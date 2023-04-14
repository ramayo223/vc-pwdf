# README for vc-pwdf code: comparing crystal structures
Description and example of use: https://doi.org/10.1039/D1CE01058A
If you find this code useful, please cite: R.A. Mayo, and E.R. Johnson, _CrystEngComm_, **2021**, _23_, 7118-7131.

# NOTE: THIS VERSION IS NOW OUTDATED. THE UPDATED VERSION HAS BEEN INTEGRATED WITH [CRITIC2](https://aoterodelaroza.github.io/critic2/). FOR BEST RESULTS, PLEASE USE THE NEW VERSION. 


## VC-PWDF overview
The VC-PWDF method is a protocol that compares two crystal structures and yields a numerical value that is 
related to the similarity of the two structures being compared. The protocol uses the simulated powder 
diffractograms of the two structures in order to yield a dissimilarity value using a cross-correlation 
function (ie. a measure of peak overlap, 
[J. Comput. Chem., 2001, 22, 273](https://doi.org/10.1002/1096-987X(200102)22:3%3C273::AID-JCC1001%3E3.0.CO;2-0)). The value yielded by the method
is a number between 0 (identical) and 1 (completely dissimilar). We have called this value the "VC-PWDF score",
and [a score \< 0.03 indicates considerable similarity and a probable match](https://pubs.rsc.org/en/content/articlehtml/2022/ce/d2ce01080a); however, user discretion is 
recommended regarding a cutoff for classifying a "match". 

The protocol is specifically 
designed to be highly effective for the comparison of crystal structures obtained under different conditions;
low/high temperatures, high pressure, or in silico-generated by force field/MM or electronic structure 
theory/DFT computational methods. Discrepencies in peak positions due to thermal expansion (or other condition deviations) are resolved by exploring various unit cell descriptions of one structure and deforming them to match the unit 
cell dimensions of the chosen reference structure. If the two structures are the same form, a coincident unit cell 
description will be found and the deformation will bring the two into alignment, yielding a low VC-PWDF score.

<figure style="width: 95%" class="align-center">
  <img src="https://github.com/ramayo223/vc-pwdf/vc-pwdf.png" alt="VC-PWDF results overlay">
</figure>
  
Refer to the following articles for details on the development, abilities, and applications of the VC-PWDF method:
- identification of target crystal structures in CSP landscapes [CrystEngComm, 2021, 23, 7118](https://pubs.rsc.org/en/content/articlehtml/2021/ce/d1ce01058a), 
- distinguishing the same structure from polymorph structures in the 
CSD [CrystEngComm, 2022, 24, 8326](https://pubs.rsc.org/en/content/articlehtml/2022/ce/d2ce01080a), 
- matching experimental PXRD to crystal structures
 [Chem. Sci., 2023](https://pubs.rsc.org/en/content/articlehtml/2023/sc/d3sc00168g) 
