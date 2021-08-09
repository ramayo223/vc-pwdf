#! /bin/bash


echo "





VC-PWDF code for comparing two crystal structures (.cif formated files)
Requires latest developer's version of critic2


KNOWN ISSUE:
- If the second structure cannot be read by critic2, the first structure given is compared with itself and will return a VC-POWDIFF value of 0

best to check both structures are critic2 readable before starting.



"  


### BUGS
# if critic can't read the 2nd file, it will write the first file a second time, you get POWDIFF 0

### KNOWN ISSUES

### TO DOs
# option to convert to reduced cell, give option of NGL DLN or no
# results table currently pretty useless, include non-corrected structure for better usefulness 


### user input of 2 structures to compare
read -p "Structure 1 [.cif]: " ref1
ref=${ref1%.cif}
read -p "Structure 2 [.cif]: " file2
file=${file2%.cif}
echo "$ref1  $ref" 
echo "$file2 $file"

read -p "Would you like to convert the structures to their Niggli reduced cell (recommended)? [y/n] " n_red
if [ ${n_red,,} = y ]
then
### use critic2 to process and normalize the formatting of the structure files
	for ciff in $ref1 $file2
	do
		sed -i "s/\r//g" $ciff
	done
	cat > cif_processing.cri << EOF
crystal $ref1
newcell niggli
write ${ref}_c.cif
write ${ref}.res
crystal $file2
newcell niggli
write ${file}_c.cif
write ${file}.res
EOF

elif [ ${n_red,,} = n ]
then
	for ciff in $ref1 $file2
	do
		sed -i "s/\r//g" $ciff
	done
	cat > cif_processing.cri << EOF
crystal $ref1
write ${ref}_c.cif
write ${ref}.res
crystal $file2
write ${file}_c.cif
write ${file}.res
EOF
fi

critic2 < cif_processing.cri > cif_processing.cro
rm cif_processing.*

### check to make sure both strucutres are same space group, give option to continue or quit if not same
spgp_1=$(grep "_space_group_IT_number" ${ref}_c.cif | awk -F ' ' '{print$2}')
spgp_2=$(grep "_space_group_IT_number" ${file}_c.cif | awk -F ' ' '{print$2}')
echo "Space_groups: $spgp_1  $spgp_2"
if [ $spgp_1 -ne $spgp_2 ]
then
	read -p "the two structures are in different space groups, would you like to continue? [y/n]
	" to_cont
	if [ ${to_cont,,} = y ]
	then
		echo "okay"
	elif [ ${to_cont,,} = n ]
	then
		echo "exiting"
		exit
	fi
fi


### check volumes to determine which structure to use as reference and which to modify
read -p "Do you want to hold one structure constant to compare against?[y/n]
" hold_choice
if [ ${hold_choice,,} = y ]
then
	read -p "Which structure would you like to hold constant? [$ref OR $file]
	" hold_cell
	if [ $hold_cell == $ref ]
	then
		point_o=$ref
		original=$file
	elif [ $hold_cell == $file ] 
	then
		original=$ref
		point_o=$file
	fi
elif [ ${hold_choice,,} = n ]
then
	echo "Structure with largest unit cell will be used as reference cell for comparison"
	V_1=$(grep "_cell_volume" ${ref}_c.cif | awk -F ' ' '{print$2}')
	V_2=$(grep "_cell_volume" ${file}_c.cif | awk -F ' ' '{print$2}')
	if (( $(bc -l <<< "$V_1 < $V_2") ))
	then
		point_o=$file
		original=$ref
	else
		original=$file
		point_o=$ref
	fi
fi
echo "Reference structure: $point_o     Structure being corrected for comparison: $original"


a_pc=$(grep CELL ${point_o}.res | awk -F ' ' '{print$3}')
b_pc=$(grep CELL ${point_o}.res | awk -F ' ' '{print$4}')
c_pc=$(grep CELL ${point_o}.res | awk -F ' ' '{print$5}')
alpha_pc=$(grep CELL ${point_o}.res | awk -F ' ' '{print$6}')
beta_pc=$(grep CELL ${point_o}.res | awk -F ' ' '{print$7}')
gamma_pc=$(grep CELL ${point_o}.res | awk -F ' ' '{print$8}')
a_b_pc=$(bc -l <<< "$a_pc - $b_pc")
a_c_pc=$(bc -l <<< "$a_pc - $c_pc")
b_c_pc=$(bc -l <<< "$b_pc - $c_pc")
echo "$point_o axes length differences: $a_b_pc $a_c_pc $b_c_pc"

a_oc=$(grep CELL ${original}.res | awk -F ' ' '{print$3}')
b_oc=$(grep CELL ${original}.res | awk -F ' ' '{print$4}')
c_oc=$(grep CELL ${original}.res | awk -F ' ' '{print$5}')
alpha_oc=$(grep CELL ${original}.res | awk -F ' ' '{print$6}')
beta_oc=$(grep CELL ${original}.res | awk -F ' ' '{print$7}')
gamma_oc=$(grep CELL ${original}.res | awk -F ' ' '{print$8}')
a_b_oc=$(bc -l <<< "$a_oc - $b_oc")
a_c_oc=$(bc -l <<< "$a_oc - $c_oc")
b_c_oc=$(bc -l <<< "$b_oc - $c_oc")
spgp_oc=$(grep "_space_group_IT_number" ${original}_c.cif | awk -F ' ' '{print$2}')
echo "$original axes length differences: $a_b_oc $a_c_oc $b_c_oc"


# axis lengths first
### check unit cell paramteters and give warning if any axis is within 1 A of another (possible mix-up of one axis with another in structure)

axdiff=1.0 # work to fix this to 5% instead of an absolute value in Angstroms
if (( $(bc -l <<< "$a_b_pc <= $axdiff && $a_b_pc >= -$axdiff") )) || (( $(bc -l <<< "$a_c_pc <= $axdiff && $a_c_pc >= -$axdiff") )) || (( $(bc -l <<< "$b_c_pc <= $axdiff && $b_c_pc >= -$axdiff") ))
then
	echo "WARNING, at least one of the axes of $point_o is within $axdiff A of another axis of the unit cell"
fi
if (( $(bc -l <<< "$a_b_oc <= $axdiff && $a_b_oc >= -$axdiff" ) )) || (( $(bc -l <<< "$a_c_oc <= $axdiff && $a_c_oc >= -$axdiff" ) )) || (( $(bc -l <<< "$b_c_oc <= $axdiff && $b_c_oc >= -$axdiff" ) ))
then
	echo "WARNING, at least one of the axes of $original is within $axdiff A of another axis of the unit cell"
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
else
	echo "$alpha_n  $beta_n  $gamma_n "
	grep 'CELL' ${point_o}.res > swap_cell.tmp
	### Make UC parameter correction
	point_ocell=`grep CELL ${point_o}.res`
	point_cell=`grep CELL swap_cell.tmp`
	echo "the unit cell used to standardise is:
	$point_ocell"
	og_cell=`grep CELL ${original}.res`
	echo "exchanging unit cell of ${original}.res:
	$og_cell
	with:
	$point_cell"
	sed "s/$og_cell/$point_cell/" ${original}.res > ${original}_VC.res
	echo "${original}_VC.res " > compare.lst 
fi

####### duplicate correction for UC-axes swaps (if any)
if [[ $check_structure ]]
then
	alpha_xc=$(grep CELL $check_structure | awk -F ' ' '{print$6}')
	beta_xc=$(grep CELL $check_structure | awk -F ' ' '{print$7}')
	gamma_xc=$(grep CELL $check_structure | awk -F ' ' '{print$8}')
	
       	if (( $(bc -l <<< "$alpha_pc == 90 && $alpha_oc != 90" ) )) || (( $(bc -l <<< "$beta_pc == 90 && $beta_oc != 90" ) )) || (( $(bc -l <<< "$gamma_pc == 90 && $gamma_oc != 90" ) ))
        then
                echo "ERROR, one of the cell angles of $original does not match up with the reference structure (90 vs !=90) $original will not undergo volume correction"
	else
		echo "$alpha_n  $beta_n  $gamma_n "
		grep 'CELL' ${point_o}.res > swap_cell.tmp
		### Make UC parameter correction
		point_ocell=`grep CELL ${point_o}.res`
		point_cell=`grep CELL swap_cell.tmp`
		echo "the unit cell used to standardise is:
		$point_ocell"
		og_cell=`grep CELL $check_structure`
		echo "exchanging unit cell of $check_structure :
		$og_cell
		with:
		$point_cell"
		sed "s/$og_cell/$point_cell/" $check_structure > ${check_structure%.res}_VC.res
		echo "${check_structure%.res}_VC.res " >> compare.lst
	fi
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
		        echo "${transform%.res}_VC.res " >> compare.lst
		fi
		let "count++"
	done
	count=1

elif [[ $spgrp_oc -gt 2 ]]
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
		        echo "${transform%.res}_VC.res " >> compare.lst
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
		        echo "${transform%.res}_VC.res " >> compare.lst
		fi
		let "count++"
	done
	count=1
fi


### run POWDIFF comparision with critic2
echo "

running POWDIFF comparisons ...
"
echo "compare $point_o.cif $original.cif" | critic2 -q > powdiff.cro
# 1 - make a file with matching structures
echo -n "$original.cif    " >> result_out.lst
grep DIFF powdiff.cro | awk '{print$4}' | tail -1 >> result_out.lst

for comparison in `cat compare.lst`
do
	echo "compare $point_o.cif $comparison" | critic2 -q > powdiff.cro
        # 1 - make a file with matching structures
        echo -n "$comparison    " >> result_out.lst
        grep DIFF powdiff.cro | awk '{print$4}' | tail -1 >> result_out.lst
done 
cat result_out.lst | sort -k2 -g > ordered_powdiff.txt

### make table of results
echo "structure POWDIFF  a       b       c       alpha   beta    gamma" > results_table.rslt
for i in `awk '{print$1}' ordered_powdiff.txt`
do
	pow=$(grep "$i" ordered_powdiff.txt | awk '{print$2}')
	a=$(grep CELL $i | awk -F ' ' '{print$3}')
        b=$(grep CELL $i | awk -F ' ' '{print$4}')
        c=$(grep CELL $i | awk -F ' ' '{print$5}')
        alpha=$(grep CELL $i | awk -F ' ' '{print$6}')
        beta=$(grep CELL $i | awk -F ' ' '{print$7}')
        gamma=$(grep CELL $i | awk -F ' ' '{print$8}')
	echo "${i%.res} $pow $a $b $c $alpha $beta $gamma" >> results_table.rslt
done

cat ordered_powdiff.txt 

### clean-up
rm *.cro
rm *.tmp

