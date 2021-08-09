#!/bin/bash
#Script for taking a nested .cif with many structures, parsing them into individual .cifs/structure, and deleting the newly created .cifs that do not meet a specified unit cell dimension criteria (user defined)

#### Step 0: print current state of script
echo "





VC-POWDF for CSP structure-energy landscapes

Filters trial structures (.cif only; convert other formats to .cif with critic2) by volume, cell lengths, crystal system and space group, within user defined deviation of a reference structure
Requires installation of latest developer's version of critic2




"
#NOTES:
#- csplit names starting at xx00, most files will have xx00 blank, some may not, Erank## may be xx(## - 1)
#
#BUGS:
#
#EDGE-CASES:
#
#IN-PROGRESS:
#- auto-axis swap: works, but 	- find/fix best axis-difference (%?), currently set at 1 angstrom 
#			        - will have issues if difference between all three axes is within axdiff (high sym cells)	
# TO-DOs
#	- cell reduction options
#	- clean up number of sig figs in UC values
#	- allow cif or res format (kinda luxury, gotta install critic2 anyway, not hard to diy)


### Step 0.5: notify of requirements and options for how to run
echo "you will need:
- a nested cif of trial structures which can be parsed using a unique identifier between structures,
- a reference cif structure 
- a chosen allowed deviation from the reference structure for match criteria (recommended default of 15%)"
echo "
The code is interactive and will prompt you for information, but you may choose to include this information in a file to feed the script instead of entering in values manually"
echo "eg:

y
big_list_of_structures.cif
y
y
ref_structure.cif
15

"
read -p "would you like to continue with manual entry? [y/n]: " man
if [ ${man,,} = y ]
then
	echo "continuing" 
else
	echo "okay, submit input file 'vc-pwdf_csp.sh < input_file.txt' "
	exit
fi

#### Step 1: direct script to the nested .cif and parse the file into the individual files for each structure, format the structure files and perform cell reductions
read -p "File containing nested crystal information [*.cif]: " xfile
echo $xfile
# pre-process the cif to get rid of ^M artifacts using sed -i "s/\r//g" file and fix any problematic data_blockcode lines 
sed -i "s/\r//g" $xfile
sed -i '/^data/s/ /_/g' $xfile
# pick pattern for spliting structures into individual files
read -p "would you like to use the default pattern for cif parsing (data_)? [y/n]: " ident
if [ ${ident,,} = y ]
then
	echo "will use 'data_' as cif seperator" 
	cif_parse=data_
else
	read -p "enter desired parsing pattern: " cif_parse
fi
# split list of structures into individual files
csplit -zs $xfile /$cif_parse/ {*}
# make a folder of the raw, individual structure files
mkdir raw_structures
for files in xx*
do
	mv $files raw_structures/${files}.cif
done


### this is the spot to branch choice of use raw, Niggli, or Delaunay cell and to clean up the cell conversions step

# read -p "what kind of unit cell reduction would you like to apply to the structures? [none/niggli/delaunay]" uc-red
# if [[ uc-red == none ]]
# then

# mkdir raw_formatted_structures
#write raw_formatted_structures/xx_o.cif

mkdir niggli_red_structures

cat > cell_conv.txt << EOF
crystal raw_structures/hh
newcell primitive
newcell niggli
write niggli_red_structures/xx_n.cif
EOF

# mkdir delaunay_red_structures
#newcell delaunay
#write delaunay_red_structures/xx_d.cif


echo "processing structures ...."
for struct in raw_structures/xx*
do
	out_o=${struct#*/}
	out=${out_o%.*}
	sed "s/xx/${out}/" cell_conv.txt > ${out}_conv.cri
	sed -i "s/hh/$out_o/" ${out}_conv.cri
	< ${out}_conv.cri critic2 > ${out}.cro
done

## Step 2: request a reference .cif structure file for the structure you want to search for to search for in this structure in the nested .cif. Format structure file if chosen, and request deviation allowance from the reference
read -p "Do you have a .cif of your reference structure? [y/n] " comp
if [ ${comp,,} = y ]
then
	read -p "filename [.cif]: " ref
	# pre-process the reference cif to get rid of ^M artifacts using sed -i "s/\r//g" file , and deal with any datablock formatting issues
	sed -i "s/\r//g" $ref
	sed -i '/^data/s/ /_/g' $ref
	out_o=${ref#*/}
        out=${out_o%.*}
        sed "s/xx/${out}/" cell_conv.txt > ${out}_conv.cri
        sed -i "s/raw_structures\/hh/$out_o/" ${out}_conv.cri
	echo "write niggli_red_structures/${out}_n.res" >> ${out}_conv.cri
        < ${out}_conv.cri critic2 > ${out}.cro
#	ref_c=original_${xfile%_*}/${out}_c.cif
	ref_n=niggli_red_structures/${out}_n.cif
#	echo "$ref_c ; $ref_n"
#### AS-IS CELL parameters
#	a_o=$(grep "_cell_length_a" $ref_c | awk -F ' ' '{print$2}')
#	b_o=$(grep "_cell_length_b" $ref_c | awk -F ' ' '{print$2}') 
#	c_o=$(grep "_cell_length_c" $ref_c | awk -F ' ' '{print$2}') 
#	alpha_o=$(grep "_cell_angle_alpha" $ref_c | awk -F ' ' '{print$2}')
#	beta_o=$(grep "_cell_angle_beta" $ref_c| awk -F ' ' '{print$2}')
#	gamma_o=$(grep "_cell_angle_gamma" $ref_c| awk -F ' ' '{print$2}')
#	V_o=$(grep "_cell_volume" $ref_c | awk -F ' ' '{print$2}')
#	CS_o=$(grep "_space_group_crystal_system" $ref_c | awk -F ' ' '{print$2}')
#	spgrp_o=$(grep "_space_group_IT_number" $ref_c | awk -F ' ' '{print$2}')
#	spgrp_name_o=$(grep "_space_group_name_H-M_alt" $ref_c | awk -F ' ' '{print$2}')
#### DELAUNAY REDUCED CELL parameters
#	a_d=$(grep "_cell_length_a" ${ref}_del.cif | awk -F ' ' '{print$2}')
#	b_d=$(grep "_cell_length_b" ${ref}_del.cif | awk -F ' ' '{print$2}') 
#	c_d=$(grep "_cell_length_c" $ref_del.cif| awk -F ' ' '{print$2}') 
#	alpha_d=$(grep "_cell_angle_alpha" $ref_del.cif| awk -F ' ' '{print$2}')
#	beta_d=$(grep "_cell_angle_beta" $ref_del.cif| awk -F ' ' '{print$2}')
#	gamma_d=$(grep "_cell_angle_gamma" $ref_del.cif| awk -F ' ' '{print$2}')
#	V_d=$(grep "_cell_volume" ${ref}_del.cif | awk -F ' ' '{print$2}')
#### NIGGLI REDUCED CELL parameters	
	a_n=$(grep "_cell_length_a" $ref_n | awk -F ' ' '{print$2}')
	b_n=$(grep "_cell_length_b" $ref_n | awk -F ' ' '{print$2}') 
	c_n=$(grep "_cell_length_c" $ref_n| awk -F ' ' '{print$2}') 
	alpha_n=$(grep "_cell_angle_alpha" $ref_n| awk -F ' ' '{print$2}')
	beta_n=$(grep "_cell_angle_beta" $ref_n| awk -F ' ' '{print$2}')
	gamma_n=$(grep "_cell_angle_gamma" $ref_n| awk -F ' ' '{print$2}')
	V_n=$(grep "_cell_volume" $ref_n | awk -F ' ' '{print$2}')
	CS_n=$(grep "_space_group_crystal_system" $ref_n | awk -F ' ' '{print$2}')
	spgrp_n=$(grep "_space_group_IT_number" $ref_n | awk -F ' ' '{print$2}')
	spgrp_name_n=$(grep "_space_group_name_H-M_alt" $ref_n | awk -F ' ' '{print$2}')
else
	echo "reference structure required to continue. If your structure is not in .cif format, used critic2 to convert to .cif before continuing"
	exit
fi

rm *.cri
rm *.cro
rm cell_conv.txt

# print out the values collected from the user or cif input
echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" >> out.log
#echo "reference structure parameters" >> out.log
#echo "$a_o $b_o $c_o $alpha_o $beta_o $gamma_o $V_o $CS_o $spgrp_name_o" >> out.log
echo "reference Niggli reduced cell parameters" >> out.log
echo "$a_n $b_n $c_n $alpha_n $beta_n $gamma_n $V_n $CS_n $spgrp_name_n" >> out.log
echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"  
#echo "reference structure parameters"
#echo "$a_o $b_o $c_o $alpha_o $beta_o $gamma_o $V_o $CS_o $spgrp_name_o" 
echo "reference Niggli reduced cell parameters" 
echo "$a_n $b_n $c_n $alpha_n $beta_n $gamma_n $V_n $CS_n $spgrp_name_n"
# work values to be usable for comparison statements - solved by running through critic2 to normalize format
#a_o=${a_o1%(*}
#b_o=${b_o1%(*}
#c_o=${c_o1%(*}
#alpha_o=${alpha_o1%(*}
#beta_o=${beta_o1%(*}
#gamma_o=${gamma_o1%(*}

read -p "Deviation tolerance (in percent) from reference unit cell parameters (volume, lengths) [15]: " dev
V_omax=$(bc -l <<< "$V_n*(1+($dev/100))")
V_omin=$(bc -l <<< "$V_n*(1-($dev/100))")
a_omax=$(bc -l <<< "$a_n*(1+($dev/100))")
a_omin=$(bc -l <<< "$a_n*(1-($dev/100))")
b_omax=$(bc -l <<< "$b_n*(1+($dev/100))")
b_omin=$(bc -l <<< "$b_n*(1-($dev/100))")
c_omax=$(bc -l <<< "$c_n*(1+($dev/100))")
c_omin=$(bc -l <<< "$c_n*(1-($dev/100))")
# tracking info for troubleshooting
echo "allowed ranges based on given deviation of $dev%" >> out.log
echo "$V_omin $V_omax" >> out.log
echo "$a_omin $a_omax ; $b_omin $b_omax ; $c_omin $c_omax" >> out.log
echo "allowed ranges based on given deviation of $dev%"
echo "$V_omin $V_omax" 
echo "$a_omin $a_omax ; $b_omin $b_omax ; $c_omin $c_omax" 
# testing end


### Step 4:  FILTERING THE STRUCTURES
# make folders and files for filtering and logs
# use for loop to pull the unit cell parameters out of each structure at a time, calculate the volume of the UC, compare against the user input criteria.
# if a structure meets the criteria, it is mv to dir which contains the selections, else, it is moved to the neg folder (auto rm at end of script)
### STEP 4.1: make log files and directories to sort into
cd niggli_red_structures/
mv ../out.log .
in_dir=`pwd`
echo "into $in_dir"
mkdir neg
mkdir hits
cp ${ref%.*}_n.* hits/
touch hits_Vlist
cat > hits_Vlist << EOF
structure a b c alpha beta gamma volume crystal_system spgrp 
$ref $a_n $b_n $c_n $alpha_n $beta_n $gamma_n $V_n $CS_n $spgrp_name_n
---------
EOF
touch neg_Vlist
cat > neg_Vlist << EOF
structure a b c alpha beta gamma volume crystal_system spgrp 
$ref $a_n $b_n $c_n $alpha_n $beta_n $gamma_n $V_n $CS_n $spgrp_name_n
---------
EOF

echo -n "compare ${ref%.*}_n.cif " > hits/powdiff.cri

##### place for prompting parameters to screen: volume (default, not un-select-able), axes lengths, crystal system, space group
## problem with order if in nested loops, not simple to just switch around or write multiple loops for at the moment, hold back at this time
#read -p "Would you like to run the default screening parameters (recommended)? [y/n]   " screen_param
#if [ ${screen_param,,} = y ]
#then
#	echo "will screen UC volume, lengths, crystal system and space group"
#else
#	echo "Please choose which parameters to screen with [y/n] (volume is deafult and cannot be un-selected)"
#	read -p "axes lengths  " uc_ax
#
#	read -p "crystal system  " uc_cs
#	read -p "space group  " uc_sg
#fi


### STEP 4.2: for loop that extracts unit cell parameters 
### STEP 4.3: Comparing the unit cell of the file to the reference structure
# then check V, then the a, b, and c lengths with OR function (should manage uncommon space groups) V will narrow the a, b, and c parameters such that the subsequent axes length comparison won't allow a larger volume
for file in xx*
do 
# pull the unit cell parameters and store into variables
#	title={grep "data_*" $file | sed /s/"data_"//}
	a=$(grep "_cell_length_a" $file | awk -F ' ' '{print$2}')
	b=$(grep "_cell_length_b" $file | awk -F ' ' '{print$2}') 
	c=$(grep "_cell_length_c" $file | awk -F ' ' '{print$2}') 
	alpha=$(grep "_cell_angle_alpha" $file | awk -F ' ' '{print$2}')
	beta=$(grep "_cell_angle_beta" $file | awk -F ' ' '{print$2}')
	gamma=$(grep "_cell_angle_gamma" $file | awk -F ' ' '{print$2}')
	V=$(grep "_cell_volume" $file | awk -F ' ' '{print$2}')
	CS=$(grep "_space_group_crystal_system" $file | awk -F ' ' '{print$2}')
	spgrp=$(grep "_space_group_IT_number" $file | awk -F ' ' '{print$2}')
	spgrp_name=$(grep "_space_group_name_H-M_alt" $file | awk -F ' ' '{print$2}')

# tracking for troubleshooting
	echo " --------------- " >> out.log
	echo  "$file $a $b $c $alpha $beta $gamma $V $CS $spgrp_name" >> out.log
	echo " --------------- " 
	echo  "$file $a $b $c $alpha $beta $gamma $V $CS $spgrp_name" 
# testing end

	if test $ref
	then 
# compare volume
		if (( $(bc -l <<< "$V <= $V_omax") )) && (( $(bc -l <<< "$V >= $V_omin") ))
		then
			echo "Cell 2 volume is within $dev% of Cell 1" >> out.log
			echo "Cell 2 volume is within $dev% of Cell 1" 
# compare crystal system		
			if [ $CS_n == $CS ]
			then
				echo "both unit cells are $CS_n"
				echo "both unit cells are $CS_n" >> out.log
				if (( $(bc -l <<< "$a >= $a_omin && $a <= $a_omax") || $(bc -l <<< "$a >= $b_omin && $a <= $b_omax") || $(bc -l <<< "$a >= $c_omin && $a <= $c_omax") )) && (( $(bc -l <<< "$b >= $a_omin && $b <= $a_omax") || $(bc -l <<< "$b >= $b_omin && $b <= $b_omax") || $(bc -l <<< "$b >= $c_omin && $b <= $c_omax") )) && (( $(bc -l <<< "$c >= $a_omin && $c <= $a_omax") || $(bc -l <<< "$c >= $b_omin && $c <= $b_omax") || $(bc -l <<< "$c >= $c_omin && $c <= $c_omax") ))
				then
# compare axes lengths			
					echo "Cell 2 axes lengths are within $dev% of Cell 1 lengths" 
					echo "Cell 2 axes lengths are within $dev% of Cell 1 lengths" >> out.log
# compare space groups		
					if [ $spgrp_n -eq $spgrp ]
					then
						echo "both structures are $spgrp_name"
						echo "both structures are $spgrp_name" >> out.log
						echo "$file $a $b $c $alpha $beta $gamma $V $CS $spgrp_name" >> hits_Vlist 
						echo -n "$file " >> hits/powdiff.cri
						mv $file hits/$file
					else
						echo "structures are different space groups"
						echo "structures are different space groups" >> out.log
						echo  "$file $a $b $c $alpha $beta $gamma $V $CS $spgrp_name" >> neg_Vlist 
					fi
				else
					echo "Cell 2 axes lengths are not within $dev% of Cell 1 lengths" 
					echo "Cell 2 axes lengths are not  within $dev% of Cell 1 lengths" >> out.log
					echo  "$file $a $b $c $alpha $beta $gamma $V $CS $spgrp_name" >> neg_Vlist 
				fi
			else
				echo "structures are different crystal systems"
				echo "structures are different crystal systems" >> out.log
				echo  "$file $a $b $c $alpha $beta $gamma $V $CS $spgrp_name" >> neg_Vlist 
			fi
		else
			echo "Cell 2 volume is not within $dev% of Cell 1" >> out.log
			echo "Cell 2 volume is not within $dev% of Cell 1" 
			echo  "$file $a $b $c $alpha $beta $gamma $V $CS $spgrp_name" >> neg_Vlist 
		fi
	fi
done

#### STEP 5: organizing

mv hits_Vlist hits/uc_pass_list.txt
mv neg_Vlist hits/uc_fail_list.txt
mv out.log hits/
cp ../$ref hits/
cp ../$xfile hits/
mv hits/ ../${xfile%.cif}_${ref%.cif}_results/
rm -r neg/

##### Step 6: Compile output from UC-screening and record structures to carry through 
cd ../${xfile%.cif}_${ref%.cif}_results/

## check whether one or more structures passed the UC screening
isfiles=$(ls xx* | wc -l)
if [[ $isfiles -eq 0 ]]
then
	echo "
	
	
	no structures pass UC screening
	clean-up and exit
	
	"
	## Tidy up
	rm *.res
	rm *.cri
	mv ../niggli_red_structures/ .
	mv ../raw_structures/ .
	mv out.log uc_screen.log
	exit
elif [[ $isfiles -eq 1 ]]	
then
	onehit=`ls xx*`
	echo "
	
	
	one structure passed UC-screen
       	comparing uncorrected POWDERS...
	
	"
	echo " " >> powdiff.cri
	critic2 < powdiff.cri > powdiff.cro
	## Reset powdiff.cri for the volume corrected structure comparisons
	echo -n "compare $ref " > powdiff.cri
	# data editing and formatting
       	# 1 - make a file with all matching structures
	echo -n "$onehit  " > ordered_powdiff.txt
	grep DIFF powdiff.cro | awk '{print$4}' | tail -1 >> ordered_powdiff.txt
       	# 2 - make a file of the structure file names 
	awk '{print$1}' ordered_powdiff.txt  >> structures_for_dma.lst
	# 3 combine with UC parameters
	touch uc_params.txt

else
## generate results of POWDIFF for uncorrected structures
	echo "
	
	
	structures passed UC-screen
       	comparing uncorrected POWDERS...
	
	"
	echo " " >> powdiff.cri
	critic2 < powdiff.cri > powdiff.cro
	## Reset powdiff.cri for the volume corrected structure comparisons
	echo -n "compare $ref " > powdiff.cri
	# data editing and formatting
       	# 1 - make a file with all matching structures
	sed -n '/DIFF = 0/,/^$/p' powdiff.cro | awk 'BEGIN{OFS="\t"}{print$1, $2}' | sort -k2 -n | sed '/^D/d' | sed '1,4d' > ordered_powdiff.txt
       	# 2 - make a file of the structure file names 
	awk '{print$1}' ordered_powdiff.txt  >> structures_for_dma.lst
	# 3 combine with UC parameters
	touch uc_params.txt
fi



for xx in `cat structures_for_dma.lst`
do
	grep "$xx" uc_pass_list.txt >> uc_params.txt
done
# make the results table from UC-screening
echo "structure	POWDIFF		a	b	c	alpha	beta	gamma	volume	cryst_syst	spgrp" > uc_results_table.rslt
join ordered_powdiff.txt uc_params.txt | awk -F ' ' 'BEGIN{OFS="\t";} {print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11}' >> uc_results_table.rslt



##### STEP: Perform volume correction on structures that pass UC-screening
echo "matches made, preparing .res files and POWDIFF list"
touch volume_correction.log
point_cell=${ref%.cif}_n.res
ref_cell=`grep CELL ${ref%.cif}_n.res`
point_o=$point_cell
grep 'CELL' ${ref%.cif}_n.res > swap_cell.tmp
### check unit cell paramteters and give warning if any axis is within axdiff A of another (possible mix-up of one axis with another in structure)
# axis lengths first
a_pc=$(grep CELL ${point_o} | awk -F ' ' '{print$3}')
b_pc=$(grep CELL ${point_o} | awk -F ' ' '{print$4}')
c_pc=$(grep CELL ${point_o} | awk -F ' ' '{print$5}')
alpha_pc=$(grep CELL ${point_o} | awk -F ' ' '{print$6}')
beta_pc=$(grep CELL ${point_o} | awk -F ' ' '{print$7}')
gamma_pc=$(grep CELL ${point_o} | awk -F ' ' '{print$8}')
a_b_pc=$(bc -l <<< "$a_pc - $b_pc")
a_c_pc=$(bc -l <<< "$a_pc - $c_pc")
b_c_pc=$(bc -l <<< "$b_pc - $c_pc")
axdiff=1
if (( $(bc -l <<< "$a_b_pc <= $axdiff && $a_b_pc >= -$axdiff") )) || (( $(bc -l <<< "$a_c_pc <= $axdiff && $a_c_pc >= -$axdiff") )) || (( $(bc -l <<< "$b_c_pc <= $axdiff && $b_c_pc >= -$axdiff") ))
then
        echo "WARNING, at least one of the axes of your reference structure is within $axdiff A of another"
        echo "WARNING, at least one of the axes of your reference structure is within $axdiff A of another" >> volume_correction.log
fi
echo "generating a res file and a volume corrected structure file for all matches"
echo "the unit cell used to standardise is:
$ref_cell"
alpha_new=$alpha_pc
beta_new=$beta_pc
gamma_new=$gamma_pc




# check all structures that pass UC screening, and make axes-swaped file if necessary
for original_o in xx*
do
	cp swap_cell.tmp swap_cell_${original_o%.cif}.tmp
	original=${original_o%.cif}
	echo "crystal $original_o" > cif_to_res.cri
	echo "write ${original_o%.cif}.res" >> cif_to_res.cri
	critic2 < cif_to_res.cri >> cif_to_res.cro
	a_oc=$(grep CELL ${original}.res | awk -F ' ' '{print$3}')
	b_oc=$(grep CELL ${original}.res | awk -F ' ' '{print$4}')
	c_oc=$(grep CELL ${original}.res | awk -F ' ' '{print$5}')
	alpha_oc=$(grep CELL ${original}.res | awk -F ' ' '{print$6}')
	beta_oc=$(grep CELL ${original}.res | awk -F ' ' '{print$7}')
	gamma_oc=$(grep CELL ${original}.res | awk -F ' ' '{print$8}')
	a_b_oc=$(bc -l <<< "$a_oc - $b_oc")
	a_c_oc=$(bc -l <<< "$a_oc - $c_oc")
	b_c_oc=$(bc -l <<< "$b_oc - $c_oc")
# check axes first
	if (( $(bc -l <<< "$a_b_oc <= $axdiff && $a_b_oc >= -$axdiff" ) )) || (( $(bc -l <<< "$a_c_oc <= $axdiff && $a_c_oc >= -$axdiff" ) )) || (( $(bc -l <<< "$b_c_oc <= $axdiff && $b_c_oc >= -$axdiff" ) ))
	then
	        echo "WARNING, at least one of the axes of $original is within $axdiff A of another"
	        echo "WARNING, at least one of the axes of $original is within $axdiff A of another" >> volume_correction.log
		if (( $(bc -l <<< "$a_b_oc <= $axdiff && $a_b_oc >= -$axdiff") ))
	        then
	                echo "crystal ${original}.res
        	        NEWCELL 0 1 0 1 0 0 0 0 1
	                write ${original}_ab.res" | critic2 -q
	                ax_swpd="_ab"
	        fi
	        if (( $(bc -l <<< "$a_c_oc <= $axdiff && $a_c_oc >= -$axdiff") ))
	        then
	                echo "crystal ${original}.res
	                NEWCELL 0 0 1 0 1 0 1 0 0
	                write ${original}_ac.res" | critic2 -q
	                ax_swpd="_ac"
	        fi
	        if (( $(bc -l <<< "$b_c_oc <= $axdiff && $b_c_oc >= -$axdiff") ))
	        then
	                echo "crystal ${original}.res
	                NEWCELL 1 0 0 0 0 1 0 1 0
	                write ${original}_bc.res" | critic2 -q
	                ax_swpd="_bc"
	        fi
	        echo "possible swapped UC axes structure ${original}${ax_swpd}.res"
	        check_structure="${original}${ax_swpd}.res"
	fi

# Angles second
	if (( $(bc -l <<< "$alpha_pc == 90 && $alpha_oc != 90" ) )) || (( $(bc -l <<< "$beta_pc == 90 && $beta_oc != 90" ) )) || (( $(bc -l <<< "$gamma_pc == 90 && $gamma_oc != 90" ) )) 
	then
		echo "ERROR, one of the cell angles of $original does not match up with the reference structure (90 vs !=90) $original will not undergo volume correction"
		echo "ERROR, one of the cell angles of $original does not match up with the reference structure (90 vs !=90) $original will not undergo volume correction" >> volume_correction.log
	else
#test		cat "swap_cell_${original_o%.cif}.tmp"
		swp_cell=`grep 'CELL' swap_cell_${original_o%.cif}.tmp`
		cp ${original_o%.cif}.res ${original_o%.cif}_VC.res
		og_cell=`grep CELL ${original_o%.cif}_VC.res`
		echo "exchanging unit cell of ${original_o%.cif}_VC.res:
		$og_cell
		with: 
		$swp_cell"	
		echo "exchanging unit cell of ${original_o%.cif}_VC.res:
		$og_cell
		with: 
		$swp_cell" >> volume_correction.log
		sed -i "s/$og_cell/$swp_cell/" ${original_o%.cif}_VC.res
		echo "${original_o%.cif}_VC.res " >> vc_hold.lst
		alpha_new=$alpha_pc
		beta_new=$beta_pc
		gamma_new=$gamma_pc
	fi

#######	####### duplicate correction for UC-axes swaps (if any)
	if [[ $check_structure ]]
	then
		cp swap_cell.tmp swap_cell_${check_structure%.res}.tmp
	#       a_xc=$(grep CELL $check_structure | awk -F ' ' '{print$3}')
	#       b_xc=$(grep CELL $check_structure | awk -F ' ' '{print$4}')
	#       c_xc=$(grep CELL $check_structure | awk -F ' ' '{print$5}')
	        alpha_xc=$(grep CELL $check_structure | awk -F ' ' '{print$6}')
	        beta_xc=$(grep CELL $check_structure | awk -F ' ' '{print$7}')
	        gamma_xc=$(grep CELL $check_structure | awk -F ' ' '{print$8}')

		if (( $(bc -l <<< "$alpha_pc == 90 && $alpha_xc != 90" ) )) || (( $(bc -l <<< "$beta_pc == 90 && $beta_xc != 90" ) )) || (( $(bc -l <<< "$gamma_pc == 90 && $gamma_xc != 90" ) )) 
		then
			echo "ERROR, one of the cell angles of $check_structure does not match up with the reference structure (90 vs !=90) $check_structure will not undergo volume correction"
			echo "ERROR, one of the cell angles of $check_structure does not match up with the reference structure (90 vs !=90) $check_structure will not undergo volume correction" >> volume_correction.log
		else
#test		cat "swap_cell_${original_o%.cif}.tmp"
			swp_cell=`grep 'CELL' swap_cell_${check_structure%.res}.tmp`
			cp $check_structure ${check_structure%.res}_VC.res
			og_cell=`grep CELL ${check_structure%.res}_VC.res`
			echo "exchanging unit cell of ${check_structure%.res}_VC.res:
			$og_cell
			with: 
			$swp_cell"	
			echo "exchanging unit cell of ${check_structure%.res}_VC.res:
			$og_cell
			with: 
			$swp_cell" >> volume_correction.log
			sed -i "s/$og_cell/$swp_cell/" ${check_structure%.res}_VC.res
			echo -n "${check_structure%.res}_VC.res " >> vc_hold.lst
			alpha_new=$alpha_pc
			beta_new=$beta_pc
			gamma_new=$gamma_pc
		fi
		unset check_structure
	fi

########## perform various transformations to account for lattice vectors used in Niggli cell

	acute_tms=("1 -1 0 0 -1 0 0 0 -1" "-1 1 0 -1 0 0 0 0 -1" "-1 0 0 -1 1 0 0 0 -1" "0 -1 0 1 -1 0 0 0 -1" "-1 0 0 0 -1 0 -1 0 1" "0 0 -1 0 -1 0 1 0 -1" "1 0 -1 0 -1 0 0 0 -1" "-1 0 1 0 -1 0 -1 0 0" "-1 0 0 0 1 -1 0 0 -1" "-1 0 0 0 -1 1 0 -1 0" "-1 0 0 0 -1 0 0 -1 1" "-1 0 0 0 0 -1 0 1 -1"
"-1 1 0 0 1 0 0 0 -1" "1 -1 0 1 0 0 0 0 -1" "1 0 0 1 -1 0 0 0 -1" "0 1 0 -1 1 0 0 0 -1" "1 0 0 0 -1 0 1 0 -1" "0 0 1 0 -1 0 -1 0 1" "-1 0 1 0 -1 0 0 0 1" "1 0 -1 0 -1 0 1 0 0" "-1 0 0 0 -1 1 0 0 1" "-1 0 0 0 1 -1 0 1 0" "-1 0 0 0 1 0 0 1 -1" "-1 0 0 0 0 1 0 -1 1")



	obtuse_tms=("-1 -1 0 0 1 0 0 0 -1" "-1 -1 0 1 0 0 0 0 -1" "1 0 0 -1 -1 0 0 0 -1" "0 1 0 -1 -1 0 0 0 -1" "1 0 0 0 -1 0 -1 0 -1" "0 0 1 0 -1 0 -1 0 -1" "-1 0 -1 0 -1 0 0 0 1" "-1 0 -1 0 -1 0 1 0 0" "-1 0 0 0 -1 -1 0 0 1" "-1 0 0 0 -1 -1 0 1 0" "-1 0 0 0 1 0 0 -1 -1" "-1 0 0 0 0 1 0 -1 -1"
"1 1 0 0 -1 0 0 0 -1" "1 1 0 -1 0 0 0 0 -1" "-1 0 0 1 1 0 0 0 -1" "0 -1 0 1 1 0 0 0 -1" "-1 0 0 0 -1 0 1 0 1" "0 0 -1 0 -1 0 1 0 1" "1 0 1 0 -1 0 0 0 -1" "1 0 1 0 -1 0 -1 0 0" "-1 0 0 0 1 1 0 0 -1" "-1 0 0 0 1 1 0 -1 0" "-1 0 0 0 -1 0 0 1 1" "-1 0 0 0 0 -1 0 1 1")

	obtuse_short_tms=("-1 -1 0 0 1 0 0 0 -1" "-1 -1 0 1 0 0 0 0 -1" "1 0 0 -1 -1 0 0 0 -1" "0 1 0 -1 -1 0 0 0 -1" "1 0 0 0 -1 0 -1 0 -1" "0 0 1 0 -1 0 -1 0 -1" "-1 0 -1 0 -1 0 0 0 1" "-1 0 -1 0 -1 0 1 0 0" "-1 0 0 0 -1 -1 0 0 1" "-1 0 0 0 -1 -1 0 1 0" "-1 0 0 0 1 0 0 -1 -1" "-1 0 0 0 0 1 0 -1 -1")


	count=1
	
	if (( $(bc -l <<< "$alpha_oc < 90" ) )) || (( $(bc -l <<< "$beta_oc < 90" ) )) || (( $(bc -l <<< "$gamma_oc < 90" ) ))
	then
		for tm in "${acute_tms[@]}"
		do
			echo $tm
			echo "crystal ${original}.res
			NEWCELL $tm
			write ${original}_tm${count}.res" | critic2 -q
			transform="${original}_tm${count}.res"
			cp swap_cell.tmp swap_cell_${transform%.res}.tmp
			alpha_tm=$(grep CELL $transform | awk -F ' ' '{print$6}')
			beta_tm=$(grep CELL $transform | awk -F ' ' '{print$7}')
			gamma_tm=$(grep CELL $transform | awk -F ' ' '{print$8}')
	
			if (( $(bc -l <<< "$alpha_pc == 90 && $alpha_tm != 90" ) )) || (( $(bc -l <<< "$beta_pc == 90 && $beta_tm != 90" ) )) || (( $(bc -l <<< "$gamma_pc == 90 && $gamma_tm != 90" ) ))
			then
			        echo "ERROR, one of the cell angles of $transform does not match up with the reference structure (90 vs !=90) $transform will not undergo volume correction"
			else
			        cat "swap_cell_${original_o%.cif}.tmp"
			        swp_cell=`grep 'CELL' swap_cell_${transform%.res}.tmp`
			        cp $transform ${transform%.res}_VC.res
			        og_cell=`grep CELL ${transform%.res}_VC.res`
			        echo "exchanging unit cell of ${transform%.res}_VC.res:
			        $og_cell
			        with:
			        $swp_cell"
			        echo "exchanging unit cell of ${transform%.res}_VC.res:
			        $og_cell
			        with:
			        $swp_cell" >> volume_correction.log
			        sed -i "s/$og_cell/$swp_cell/" ${transform%.res}_VC.res
			        echo -n "${transform%.res}_VC.res " >> vc_hold.lst
			fi
			let "count++"
		done
		count=1

	elif [[ $spgrp_n -gt 2 ]]
	then
	        for tm in "${obtuse_short_tms[@]}"
	        do
	                echo $tm
	                echo "crystal ${original}.res
	                NEWCELL $tm
	                write ${original}_tm${count}.res" | critic2 -q
	                transform="${original}_tm${count}.res"
	                cp swap_cell.tmp swap_cell_${transform%.res}.tmp
	                alpha_tm=$(grep CELL $transform | awk -F ' ' '{print$6}')
	                beta_tm=$(grep CELL $transform | awk -F ' ' '{print$7}')
	                gamma_tm=$(grep CELL $transform | awk -F ' ' '{print$8}')
	
	                if (( $(bc -l <<< "$alpha_pc == 90 && $alpha_tm != 90" ) )) || (( $(bc -l <<< "$beta_pc == 90 && $beta_tm != 90" ) )) || (( $(bc -l <<< "$gamma_pc == 90 && $gamma_tm != 90" ) ))
	                then
	                        echo "ERROR, one of the cell angles of $transform does not match up with the reference structure (90 vs !=90) $transform will not undergo volume correction"
	                else
	                        cat "swap_cell_${original_o%.cif}.tmp"
	                        swp_cell=`grep 'CELL' swap_cell_${transform%.res}.tmp`
	                        cp $transform ${transform%.res}_VC.res
	                        og_cell=`grep CELL ${transform%.res}_VC.res`
	                        echo "exchanging unit cell of ${transform%.res}_VC.res:
	                        $og_cell
	                        with:
	                        $swp_cell"
	                        echo "exchanging unit cell of ${transform%.res}_VC.res:
	                        $og_cell
	                        with:
	                        $swp_cell" >> volume_correction.log
	                        sed -i "s/$og_cell/$swp_cell/" ${transform%.res}_VC.res
	                        echo "${transform%.res}_VC.res " >> vc_hold.lst
	                fi
	                let "count++"
	        done
	        count=1

	else
		for tm in "${obtuse_tms[@]}"
		do
			echo $tm
			echo "crystal ${original}.res
			NEWCELL $tm
			write ${original}_tm${count}.res" | critic2 -q
			transform="${original}_tm${count}.res"
			cp swap_cell.tmp swap_cell_${transform%.res}.tmp
			alpha_tm=$(grep CELL $transform | awk -F ' ' '{print$6}')
			beta_tm=$(grep CELL $transform | awk -F ' ' '{print$7}')
			gamma_tm=$(grep CELL $transform | awk -F ' ' '{print$8}')
	
			if (( $(bc -l <<< "$alpha_pc == 90 && $alpha_tm != 90" ) )) || (( $(bc -l <<< "$beta_pc == 90 && $beta_tm != 90" ) )) || (( $(bc -l <<< "$gamma_pc == 90 && $gamma_tm != 90" ) ))
			then
			        echo "ERROR, one of the cell angles of $transform does not match up with the reference structure (90 vs !=90) $transform will not undergo volume correction"
			else
			        cat "swap_cell_${original_o%.cif}.tmp"
			        swp_cell=`grep 'CELL' swap_cell_${transform%.res}.tmp`
			        cp $transform ${transform%.res}_VC.res
			        og_cell=`grep CELL ${transform%.res}_VC.res`
			        echo "exchanging unit cell of ${transform%.res}_VC.res:
			        $og_cell
			        with:
			        $swp_cell"
			        echo "exchanging unit cell of ${transform%.res}_VC.res:
			        $og_cell
			        with:
			        $swp_cell" >> volume_correction.log
			        sed -i "s/$og_cell/$swp_cell/" ${transform%.res}_VC.res
			        echo -n "${transform%.res}_VC.res " >> vc_hold.lst
			fi
			let "count++"
		done
		count=1
	fi
done
rm *.tmp
	
#### STEP 7: Compare powder patterns of hit structures with critic2 if reference .cif is used and a structure fitting search criteria is obtained
#if [ -n "${ref}" ] 


current_dir1=`pwd`
current_dir=${current_dir1##*tol/}
isvcfile=$(ls *_VC.res | wc -l)
if [[ isvcfile -eq 0 ]]
then
	echo "
	
	
	no structures compatible with volume correction
	clean-up and exit
	
	"
	## Tidy up
	mkdir uc_hits/
	mv xx*.cif uc_hits/
	rm *.res
	rm *.cri
	rm *.cro
	mv ../niggli_red_structures/ .
	mv ../raw_structures/ .
	rm ordered_powdiff*
	rm uc_params.txt
	mv out.log uc_screen.log
	exit
elif [[ isvcfile -eq 1 ]]	
then
	echo "
	
	
	one structure volume corrected
       	comparing VC-POWDERS...
	
	"
	onehit=`ls *_VC.res`
	echo "compare $ref $onehit" | critic2 -q > powdiff.cro
       	# 1 - make a file with matching structures
	echo -n "$onehit  " > ordered_powdiff_VC.txt
	grep DIFF powdiff.cro | awk '{print$4}' | tail -1 >> ordered_powdiff_VC.txt
       	# 2 - make a file of the structure file names to CONV with DMACRYS
	awk '{print$1}' ordered_powdiff_VC.txt  > structures_for_dma.lst
	echo "structure	POWDIFF" > vc_results_table.rslt
	cat ordered_powdiff_VC.txt >> vc_results_table.rslt
else
	echo "
	
	
	structures volume corrected
       	comparing VC-POWDERS...
	($current_dir)	

	"
	for comparison in `cat vc_hold.lst`
	do
		echo "compare $ref $comparison" | critic2 -q > powdiff.cro
	        # 1 - make a file with matching structures
	        echo -n "$comparison    " >> result_out.lst
	        grep DIFF powdiff.cro | awk '{print$4}' | tail -1 >> result_out.lst
	done
	cat result_out.lst | sort -k2 -g > ordered_powdiff_VC.txt
       	# 2 - make a file of the structure file names to CONV with DMACRYS
	awk '{print$1}' ordered_powdiff_VC.txt  > structures_for_dma.lst
	echo "structure	POWDIFF" > vc_results_table.rslt
	cat ordered_powdiff_VC.txt >> vc_results_table.rslt   			
fi


## Tidy up
mkdir VC_structures/
mv *_VC.res VC_structures/
mkdir uc_hits/
mv xx*.cif uc_hits/
rm *.res
rm *.cri
rm *.cro
mv ../niggli_red_structures/ .
mv ../raw_structures/ .
rm ordered_powdiff*
rm uc_params.txt
mv out.log uc_screen.log


## retro-fix duplicates and uc-screen results
cp vc_results_table.rslt VC_structures/vc_results_table_wdups.rslt
list=$(awk '{print$1}' vc_results_table.rslt)
for i in $list
do
       search=${i%%n_*}
       awk -i inplace "/$search/&&c++>0 {next} 1" vc_results_table.rslt
done

cp uc_results_table.rslt uc_hits/
singles_list=$(awk '{print$1}' vc_results_table.rslt)
for structure in $singles_list
do
       grep ${structure%%n_*} uc_results_table.rslt >> uc_results_singles.rslt
done


echo "POWDIFF results for raw structures"
cat uc_results_singles.rslt
echo "VC-POWDIFF results for volume-corrected structures"
cat vc_results_table.rslt





