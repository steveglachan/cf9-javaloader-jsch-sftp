# CF9 + JavaLoader + JSch sFTP
*Proof of concept.*

## Outcome
Use JavaLoader to load the JSCH Java library in Adobe ColdFusion 9 web applications, to successfully make outbound sFTP connections.

## The problem to solve
A partner we work with and transfer XML file to periodically via FTP, reached out to let us know they would be upgrading to use sFTP and that we would need to make accomodations within our application.


### Using Adobe ColdFusion 9 and sFTP 

Attempting to use the [CFFTP tag in ColdFusion 9 (CF9)](https://cfdocs.org/cfftp) to transfer files over sFTP, failed due to incompatible libraries packed with CF9. This issue may also affect other version of Adobe ColdFusion (untested).

*Example CFFTP tage implamentation in ColdFusion:*
```coldfusion
<cfftp action = "open"
username = "myusername"
connection = "My_query"
password = "mypassword"
fingerprint = "12:34:56:78:AB:CD:EF:FE:DC:BA:87:65:43:21"
server = "ftp.example.com"
secure = "yes">
```
*Resulting error:*
> **Detail:** Verify your connection attributes: username, password, server, fingerprint, port, key, connection, proxyServer, and secure (as applicable). 
> 
> **Error:** Algorithm negotiation fail.
> 
> **Message:** An error occurred while establishing an sFTP connection.

## The solution
It was clear, an alternate approach was needed to bypass ColdFusion's built-in libraries.

### Dependencies
* [jsch-0.1.55.jar](http://www.jcraft.com/jsch/)
* [JavaLoader](https://github.com/markmandel/JavaLoader)

### References
* [JSch sFTP Example (sFTP.java)](http://www.jcraft.com/jsch/examples/Sftp.java.html)
* [Running Java libraries in ColdFusion](https://www.compoundtheory.com/running-your-own-java-libraries-in-coldfusion-with-style/)

### POC code for testing
```coldfusion
<cfscript>

paths[1] = expandpath("./lib/jsch-0.1.55.jar");
loader = createObject("component", "lib.javaloader.JavaLoader").init(paths); // (takes an array of paths)
jsch = loader.create("com.jcraft.jsch.JSch").init();
//jsch.setConfig("PreferredAuthentications", "publickey,keyboard-interactive,password");

/***
* Instantiate each Class we need loaded from the JAR: 
**/
jSession = loader.create("com.jcraft.jsch.Session");
jChannel = loader.create("com.jcraft.jsch.Channel");
jChannelSFTP = loader.create("com.jcraft.jsch.ChannelSftp").init();

// Additional Classes note used in this script:
//jUserInfo = loader.create("com.jcraft.jsch.UserInfo");
//jLogger = loader.create("com.jcraft.jsch.Logger");

/***
* Properties is a Util available within CF Java libraries already.
* This is used to check against trusted hosts.
**/
jProperties = CreateObject("java", "java.util.Properties");
jProperties.put("StrictHostKeyChecking", "no");

/***
* Pre-set sFTP credentials.
* This should be extracted outside of the application. 
**/
host = "ftp.server.com";
username = "sftp_username";
password = "sftp_password";
portNumber = "2022";

/***
* Ensure certain values are type-cast for Java usage: 
**/
javaCast("String", "host");
javaCast("String", "username");

/***
* Set up the SSH client: 
**/
jsession = jsch.getSession(username, host, portNumber);
jsession.setPassword(password);
jsession.setConfig(jProperties);
// Alternative modifiers:
//jsession.setPort(portNumber);
//jsession.setUserInfo(jUserInfo);


getPageContext().getOut().flush(); // (flush page output)
jsession.connect();
writeOutput("Connected.<br><br>");

/***
* Set up the sFTP channel for file transfer.
**/
writeOutput("Opening sFTP channel ...<br><br>");
channel = jsession.openChannel("sftp");
channel.connect();

/***
* Prep file(s) for PUT action and transfer.
**/
datetime = now();
localFile = expandpath("./data/test.xml");
remoteDir = "test/";
remoteFile = "test_#DateFormat(datetime, "yyyy-mm-dd")#_#TimeFormat(datetime, "H.mm.ss")#.xml";

writeOutput("Putting file (#localfile#) ...<br>");
channel.put(localFile, remoteDir & remoteFile);
writeOutput("File transfer complete ...<br><br>");

/***
* List remote directory file contents.
* Java returns a Vector (CF Array).
**/
fileList = channel.ls("test/");

writeOutput("Target directory file list (remote) ...<br>");
writeOutput("<ul>");
for(x=1; x LTE arraylen(fileList); x++) {
    writeOutput("<li>");
    writeOutput(fileList[x].getFilename());
    writeOutput("</li>");
}
writeOutput("</ul>");

/***
* Close the sFTP channel.: 
**/
channel.disconnect();
writeOutput("Disconnected channel ...<br>");

/***
* Close the SSH client: 
**/
jsession.disconnect();
writeOutput("Disconnected. <br>");

</cfscript>
```

#### Example POC code output
```
Connected.

Opening sFTP channel ...

Putting file (D:\content\wwwtesting\sftp\data\test.xml) ...
File transfer complete ...

Target directory file list (remote) ...

* test_2021-10-07_22.29.54.xml
* test_2021-10-07_22.29.56.xml
* test_2021-10-07_22.29.57.xml
* test_2021-10-07_22.29.59.xml
* test_2021-10-07_22.30.00.xml
* test_2021-10-08_10.24.45.xml
* test_2021-10-08_10.24.47.xml
* test_2021-10-08_10.35.00.xml

Disconnected channel ...
Disconnected.
```
