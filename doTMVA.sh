#!/bin/bash

DOTMVA=0
DOREADXML_SAVEHIST=1

#
PTMIN=(6)
PTMAX=(1000)
DRBIN=(0 0.05 0.1 0.2 0.5)
COLSYST=('pp')
MVA='CutsSA'
#
INPUTSNAME=('/export/d00/scratch/jwang/Djets/MC/tmva_DjetFiles_20170506_pp_5TeV_TuneCUETP8M1_Dfinder_MC_20170404_pthatweight_jetpt_80_jeteta_0p3_1p6.root')
INPUTBNAME=('/export/d00/scratch/jwang/Djets/data/tmva_DjetFiles_HighPtJet80_pp_5TeV_Dfinder_2april_v1_jetpt_80_jeteta_0p3_1p6.root')
CUT=('TMath::Abs(Dtrk1Eta)<2.0&&TMath::Abs(Dtrk2Eta)<2.0&&Dtrk1Pt>2.0&&Dtrk2Pt>2.0&&(Dtrk1PtErr/Dtrk1Pt)<0.3&&(Dtrk2PtErr/Dtrk2Pt)<0.3&&Dtrk1highPurity&&Dtrk2highPurity&&fabs(Dy)<2.0&&(DsvpvDistance/DsvpvDisErr)>0.0&&Dalpha<0.2&&Dchi2cl>0.05')
MYCUTS=("${CUT[0]}&&Dgen==23333")
MYCUTB=("${CUT[0]}&&TMath::Abs(Dmass-1.865)>0.1&&TMath::Abs(Dmass-1.865)<0.15")

INPUTMCNAME=("${INPUTSNAME[0]}")
INPUTDANAME=("${INPUTBNAME[0]}")

##
nPT=$((${#PTMIN[@]}))
nDR=$((${#DRBIN[@]}-1))
nCOL=${#COLSYST[@]}

#
rt_float_to_string=-1
float_to_string()
{
    if [[ $# -ne 1 ]]
    then
        echo "  Error: invalid argument number - float_to_string()"
        exit 1
    fi
    part1=`echo $1 | awk -F "." '{print $1}'`
    part2=`echo $1 | awk -F "." '{print $2}'`
    rt_float_to_string=${part1:-0}p${part2:-0}
}
NC='\033[0m'

#
FOLDERS=("myTMVA/weights" "myTMVA/ROOT" "readxml/rootfiles")
for i in ${FOLDERS[@]}
do
    if [ ! -d $i ]
    then
	mkdir -p $i
    fi
done

##

# TMVAClassification.C #
if [ $DOTMVA -eq 1 ]
then
    j=0
    while ((j<$nCOL))
    do
        i=0
        while ((i<$nPT))
        do
	    float_to_string ${PTMIN[i]}
            tPTMIN=$rt_float_to_string
            float_to_string ${PTMAX[i]}
            tPTMAX=$rt_float_to_string
	    l=0
	    while ((l<$nDR))
	    do
		float_to_string ${DRBIN[l]}
                tDRMIN=$rt_float_to_string
                float_to_string ${DRBIN[l+1]}
                tDRMAX=$rt_float_to_string

		cd myTMVA/
		echo -e "-- Processing \033[1;33m TMVAClassification.C ${NC} pT bin: \033[1;32m${PTMIN[i]} - ${PTMAX[i]} GeV/c${NC}, deltaR range: \033[1;32m${DRBIN[l]} - ${DRBIN[l+1]}${NC}"
		echo
		#./TMVAClassification.exe ${INPUTSNAME[j]} ${INPUTBNAME[j]} ${MYCUTS[j]} ${MYCUTB[j]} ${COLSYST[j]} ${PTMIN[i]} ${PTMAX[i]} ${DRBIN[l]} ${DRBIN[l+1]}
		root -l -b -q 'TMVAClassification.C+('\"${INPUTSNAME[j]}\"','\"${INPUTBNAME[j]}\"','\"${MYCUTS[j]}\"','\"${MYCUTB[j]}\"','\"${COLSYST[j]}\"','${PTMIN[i]}','${PTMAX[i]}','${DRBIN[l]}','${DRBIN[l+1]}')'
		mv weights/TMVAClassification_${MVA[k]}.weights.xml weights/TMVA_${MVA[k]}_${COLSYST[j]}_pt_${tPTMIN}_${tPTMAX}_deltaR_${tDRMIN}_${tDRMAX}.weights.xml
		mv weights/TMVAClassification_${MVA[k]}.class.C weights/TMVA_${MVA[k]}_${COLSYST[j]}_pt_${tPTMIN}_${tPTMAX}_deltaR_${tDRMIN}_${tDRMAX}.class.C
		cd ..

		l=$(($l+1))
	    done    
	    i=$(($i+1))
        done
        j=$(($j+1))
    done    
fi

# readxml.cc #
if [ $DOREADXML_SAVEHIST -eq 1 ]
then
    j=0
    while ((j<$nCOL))
    do
        i=0
        while ((i<$nPT))
        do
	    float_to_string ${PTMIN[i]}
            tPTMIN=$rt_float_to_string
            float_to_string ${PTMAX[i]}
            tPTMAX=$rt_float_to_string
	    l=0
	    while ((l<$nDR))
            do
                float_to_string ${DRBIN[l]}
                tDRMIN=$rt_float_to_string
                float_to_string ${DRBIN[l+1]}
                tDRMAX=$rt_float_to_string

                cd readxml/
		echo -e "-- Processing \033[1;33m readxml_savehist.cc ${NC} pT bin: \033[1;32m${PTMIN[i]} - ${PTMAX[i]} GeV/c${NC}, deltaR range: \033[1;32m${DRBIN[l]} - ${DRBIN[l+1]}${NC}"
		if [ -f "../myTMVA/weights/TMVA_${MVA[k]}_${COLSYST[j]}_pt_${tPTMIN}_${tPTMAX}_deltaR_${tDRMIN}_${tDRMAX}.weights.xml" ]
		then
		    TEND=TMVA_${MVA[k]}_${COLSYST[j]}_pt_${tPTMIN}_${tPTMAX}_deltaR_${tDRMIN}_${tDRMAX}
		    root -b -q 'readxml_savehist.cc+('\"${INPUTMCNAME[j]}\"','\"${INPUTDANAME[j]}\"','\"rootfiles/fmass_${TEND}\"','\"../myTMVA/weights/${TEND}.weights.xml\"','\"${COLSYST[j]}\"','${PTMIN[i]}','${PTMAX[i]}','${DRBIN[l]}','${DRBIN[l+1]}')'
		    #./readxml_hist.exe ${INPUTMCNAME[j]} ${INPUTDANAME[j]} rootfiles/fmass_TMVA_${MVA[k]}_${COLSYST[j]}_pt_${tPTMIN}_${tPTMAX}_deltaR_${tDRMIN}_${tDRMAX}.root ../myTMVA/weights/TMVA_${MVA[k]}_${COLSYST[j]}_pt_${tPTMIN}_${tPTMAX}_deltaR_${tDRMIN}_${tDRMAX}.weights.xml ${COLSYST[j]} ${PTMIN[i]} ${PTMAX[i]} ${DRBIN[l]} ${DRBIN[l+1]}
		else
		    echo "  Error: no weight file: ../myTMVA/weights/TMVA_${MVA[k]}_${COLSYST[j]}_pt_${tPTMIN}_${tPTMAX}_deltaR_${tDRMIN}_${tDRMAX}.weights.xml"
		fi
                cd ..
		echo
		l=$(($l+1))
            done
            i=$(($i+1))
        done
        j=$(($j+1))
    done
fi