#/bin/sh
gpg --yes --always-trust --output dynare-object-signing.p12 --decrypt dynare-object-signing.p12.gpg
ERROR_CODE=$?
if [ $ERROR_CODE -ne 0 ]; then
    touch impossible-to-sign-dynare
else
    rm -f impossible-to-sign-dynare
fi
