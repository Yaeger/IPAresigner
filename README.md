# IPAresigner
Wrapper for generating entitlements.xml file and resigning an IPA 

This application wraps around the following commands to quickly resign IPA files.

security cms -D -i Payload/*.app/embedded.mobileprovision<br>
security find-identity -pcodesigning -v<br>
codesign --force -vvvv --sign <unique certificate ID> --entitlements ./new-entitlements.xml ./Payload/*.app<br>

Dependancies:
Apple developer account
  - Installed signing certificate
  - Associated embedded.mobileprovision configured to include the target device ID

Usage: <br>
copy the embedded.mobileprovision to the working directory<br>
copy the file.ipa to the working directory<br>

run: resigner \<file.api\> 

What to expect:<br>
  - The application should extract the ipa to the Payload directory.<br>
  - Create a teml.plist file from the embedded.mobileprovision Entitlements:application-identifier.<br>
  - Create a entitlements.xml file.<br>
  - Copy the embedded.mobileprovision into the ./Payload/*.app directory.<br>
  - Remove any old signatures.<br> 
  - Sign the application.<br>
  - Zip up the application into a new shiny ipa file called "resined.ipa"<br>
