#/bin/sh
gpg --yes --always-trust --output snapshot-manager-key.tar --decrypt snapshot-manager-key.tar.gpg
ERROR_CODE=$?
if [ $ERROR_CODE -ne 0 ]; then
    touch impossible-to-push-dynare
else
    rm -f impossible-to-push-dynare
fi
