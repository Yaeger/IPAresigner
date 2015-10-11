# IPAresigner
Wrapper for generating entitlements.xml file and resigning an IPA 

This application wraps around the following commands to quickly resign IPA files.

security cms -D -i Payload/*.app/embedded.mobileprovision
security find-identity -pcodesigning -v
codesign --force -vvvv --sign <unique certificate ID> --entitlements ./new-entitlements.xml ./Payload/*.app

Dependancies:
Apple developer account
  - Installed signing certificate
  - Associated embedded.mobileprovision configured to include the target device ID

Usage: 
copy the embedded.mobileprovision to the working directory
copy the file.ipa to the working directory
run: resigner <file.api> 

What to expect:
-The application should extract the ipa to the Payload directory.
-Create a teml.plist file from the embedded.mobileprovision Entitlements:application-identifier.
-Create a entitlements.xml file.
-Copy the embedded.mobileprovision into the ./Payload/*.app directory.
-Remove any old signatures. 
-Sign the application.
-Zip up the application into a new shiny ipa file called "resined.ipa"
