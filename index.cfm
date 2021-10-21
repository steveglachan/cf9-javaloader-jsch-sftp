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