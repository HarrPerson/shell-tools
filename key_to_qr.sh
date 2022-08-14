#!/bin/bash

gpgimportshow="gpg --import --import-options show-only --fingerprint"
gpgimport="gpg --import"
gpglistsecret="gpg --list-secret-keys --fingerprint"
gpgexport="gpg --export-secret-keys"
sedmagic="sed -n '2{p;q}'"

fingerprint1=""
fingerprint2=""

function convertToPDF {
    picture=$1
    keyID=$2

    convert ${picture} \
        -gravity South \
        -background black \
        -splice 0x2 \
        -font helvetica \
        -background white \
        -splice 0x150 \
        -pointsize 16 \
        -annotate +0+0 "${keyID}" \
        -bordercolor black -border 2x2 \
        ${picture}.pdf 
}


case "$1" in
        genqr)
            gpgkeyid=${2}
            keyoutput=${3}
            exportfile="${keyoutput}/${gpgkeyid}.svg"

            echo "Generate QR code for ${gpgkeyid}:"
            ${gpglistsecret} "${gpgkeyid}"

            ${gpgexport} ${gpgkeyid} | base64 -w 0 | qrencode -l Q -t SVG -o "${exportfile}"
            returncode=$?
            if [ ! ${returncode} -eq 0 ]; then
                echo "Something went wrong during exporting with return code ${returncode}. Aborting."
                exit 1
            fi
            echo "Read out QR Code from ${exportfile}:"
            zbarimg -q "${exportfile}"| cut -c 9- | base64 -d | ${gpgimportshow}
            returncode=$?
            if [ ! ${returncode} -eq 0 ]; then
                echo "Something went wrong during qrcode verify with return code ${returncode}. Aborting."
                exit 1
            fi

            #echo "${fingerprint1}"
            #echo "${fingerprint2}"
            qrcaption=$(${gpglistsecret} ${gpgkeyid})
            convertToPDF "${exportfile}" "${qrcaption}"
            echo "Exported to ${exportfile} and ${exportfile}.pdf"
            exit 0
            ;;
        importqr)
            importfile=${2}
            echo "Read out QR Code from ${importfile}:"
            zbarimg -q "${importfile}"| cut -c 9- | base64 -d | ${gpgimportshow}
            zbarimg -q "${importfile}"| cut -c 9- | base64 -d | ${gpgimport}
            returncode=$?
            if [ ! ${returncode} -eq 0 ]; then
                echo "Something went wrong during qrcode verify with return code ${returncode}. Aborting."
                exit 1
            fi
            exit 0
            ;;
        obfuscateqr)
            keyoutput=${2}
            exportfile="${keyoutput}/obfuscateqr_$(date +%Y-%M-%d-%H%M%S%N).svg"

            dd if=/dev/urandom bs=256 count=4 | base64 | qrencode -l Q -t SVG -o ${exportfile}
            convert ${exportfile} "${exportfile}.pdf"
            returncode=$?
            if [ ! ${returncode} -eq 0 ]; then
                echo "Something went wrong during exporting with return code ${returncode}. Aborting."
                exit 1
            fi
            exit 0
            ;;

        *)
            echo $"Usage: $0 {genqr <keyid> <outfolder>|importqr <importfile>}|obfuscateqr <outfolder>"
            exit 1
 
esac

exit 0
