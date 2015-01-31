Slingshot.fileRestrictions "myFileUploads",
  allowedFileTypes: [
    "image/png"
    "image/jpeg"
    "image/jpg"
  ]
  maxSize: 10 * 1024 * 1024 # 10 MB (use null for unlimited)

if Meteor.isServer
  Meteor.startup ->
		Slingshot.createDirective "myFileUploads", Slingshot.S3Storage,
		  bucket: "jlee-photoapp"
		  acl: "public-read"
		  authorize: ->
		    
		    #Deny uploads if user is not logged in.
		    unless @userId
		      message = "Please login before uploading files."
		      throw new Meteor.Error("Login Required", message)
		    true

		  key: (file) ->
		    
		    #Store file into a directory by the user's username.
		    user = Meteor.users.findOne(@userId)
		    #regex filename to lowercase, strip leading and trailing whitespace, replace spaces to dash
		    fileName = file.name.toLowerCase().replace(/^\s+|\s+$/g,'').replace(/\s+/g, "-")
		    "dev_meteor/" + user._id + "/" + Date.now() + "-" + fileName
		 