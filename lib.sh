###### -*- mode:sh -*-

# Yealink's encryption tool generates a "random" key using characters
# [a-zA-Z0-9].  It uses this key directly as a stream of bytes to
# encrypt the configuration file with AES-128-ECB.  Then it encrypts
# this key with a "common" key distributed as part of the firmware and
# the encryption tool and writes the result to a second file, also
# using AES-128-ECB.

encrypt () {
 local key="$1"
  openssl enc -aes-128-ecb -nopad \
    -K $(printf "$key" | xxd -p)
}

decrypt () {
  local key="$1"
  openssl enc -aes-128-ecb -d -nopad \
    -K $(printf "$key" | xxd -p)
}

encrypt_key () { encrypt 'EKs35XacP6eybA25'; }
decrypt_key () { decrypt 'EKs35XacP6eybA25'; }
encrypt_cfg () { encrypt "$1"; }
decrypt_cfg () { decrypt "$1"; }

test_lib () {
  printf "Test that key decryption/encryption produces identical results..."
  (decrypt_key < test/test_Security.enc | encrypt_key | diff test/test_Security.enc -) \
    && printf "Success\n" || printf "Failure\n"
  printf "Test that we produce identical encrypted configs..."
  local key=$(decrypt_key < test/test_Security.enc)
  (decrypt_cfg $key < test/test.cfg | encrypt_cfg $key | diff test/test.cfg -) \
    && printf "Success\n" || printf "Failure\n"
}
