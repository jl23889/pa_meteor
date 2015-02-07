Photos = new Mongo.Collection("photos")
Albums = new Mongo.Collection("albums")

Schemas = {}
Schemas.Photo = new SimpleSchema(

  owner_id: 
    type: String

  ownerUsername:
    type: String
  
  url: 
    type: String
  
  dateCreated: 
    type: Date

  title:
    type: String
    label: "Title"
    max: 200
  
  categories:
    type: [String]
    label: "Categories"
    optional: true
    autoform: 
      type: "select2",
      afFieldInput:
        multiple: true
      options: ->
        [
          {label: "Animal", value: "animal"},
          {label: "Cityscape", value: "cityscape"},
          {label: "Design", value: "design"},
          {label: "Landscape", value: "landscape"},
          {label: "Plants", value: "plants"}
        ]
  
  accessControl:
    type: String
    label: "Set Access Level"
    autoform: 
      type: "select-radio-inline",
      options: ->
        [
          {label: "Public", value: "public"},
          {label: "Private", value: "private"}
        ]
)
Photos.attachSchema Schemas.Photo

## paginate photos
PhotoPages = new Meteor.Pagination Photos,
  perPage: 20
  sort: 
    createdAt: -1    

if Meteor.isClient

  # TempPhotos = new Mongo.Collection("tempPhotos")

  Router.configure(
    layoutTemplate: 'ApplicationLayout'
  )

  Router.onBeforeAction AccountsTemplates.ensureSignedIn, except: [
    'photos'
    'albums'
    'sign_in'
    'sign_out'
    'atSignIn'
    'atSignUp'
    'atForgotPassword'
  ]

  Router.route '/', ->
    @render 'Welcome'

  Router.route '/photos', ->
    @render 'Photos'

  Router.route '/photo/edit/:_id', (->
    $photo = Photos.findOne _id: @params._id
    if Meteor.user()._id == $photo.owner_id
      @render 'PhotoEdit',
        data: ->
          Photos.findOne _id: @params._id
    else 
      @render 'UserAccessDenied'
  ),
    name: "photo.edit"
    
  Router.route '/albums', ->
    @render 'Albums'

  Router.route '/sign_in', ->
    $('#navbar-left').trigger 'close.mm'
    @render 'SignIn'

  Router.route '/sign_out', ->
    Meteor.logout()
    $('#navbar-left').trigger 'close.mm'
    @render 'Welcome'

  Router.route '/home', ->
    @render 'Home'
    
  Router.route '/profile/edit', ->
    @render 'EditProfile'

  Router.route '/profile/settings', ->
    @render 'EditSettings'

  Router.route '/uploadPhoto', ->
    @render 'UploadPhoto',

  toastr.options = 
    closeButton: true,
    positionClass: "toast-bottom-left"

  Template.registerHelper "Photos", Photos

  ##useraccount templates
  ##
  AccountsTemplates.removeField('email');
  AccountsTemplates.addFields [
    ## add username field; allow signin by username or email
    {
      _id: 'username'
      type: 'text'
      required: true
      func: (value) ->
        if Meteor.isClient
          self = this
          Meteor.call 'userExists', value, (err, userExists) ->
            if !userExists
              self.setSuccess()
            else
              self.setError userExists
            self.setValidating false
        # Server
        Meteor.call 'userExists', value
    }
    {
      _id: 'email'
      type: 'email'
      required: true
      displayName: 'email'
      re: /.+@(.+){2,}\.(.+){2,}/
      errStr: 'Invalid email'
    }
  ]
    
  Template.leftNav.rendered = ->
    this.$('#navbar-left').mmenu(
      classes: "mm-white",
      header: 
        add: true,
        title: "Photoapp",
        update: true
    )

    #	Choose photo owner
    $sortPhotos = this.$('#sort-photos')
    $ownedBy = $("#setting-ownedBy .mm-counter")
    this.$("#ownedBy").find("li span").click ->
      $ownedBy.text $(this).text()
      $sortPhotos.trigger "open.mm"

    # Close mmenu after hitting link
    $('.photos-link').click ->
      $('#navbar-left').trigger "close.mm"
    $('.albums-link').click ->
      $('#navbar-left').trigger "close.mm"

  Template.leftNavSignIn.rendered = ->
    this.$('#navbar-left').mmenu(
      classes: "mm-white",
      header: 
        add: true,
        title: "Photoapp",
        update: true
    )  

    #	Choose photo owner
    $sortPhotos = this.$('#sort-photos')
    $ownedBy = $("#setting-ownedBy .mm-counter")
    this.$("#ownedBy").find("li span").click ->
      $ownedBy.text $(this).text()
      $sortPhotos.trigger "open.mm"
    
    # Close mmenu after hitting link
    $('.photos-link').click ->
      $('#navbar-left').trigger "close.mm"
    $('.albums-link').click ->
      $('#navbar-left').trigger "close.mm"

  Template.photo.rendered = ->
    ## attach fluidbox 
    ## docs@https://github.com/terrymun/Fluidbox
    $caption = this.$('.caption')
    $fluidbox = this.$('a[rel="fluidbox"]')
    # detect mobile by browser size
    isMobile = window.matchMedia("only screen and (max-width: 768px)").matches
    $fluidbox.fluidbox(
      isMobile: isMobile
    ).on( 'openstart', ->
      $caption.hide()
    )

  Template.photo.events(
    'mouseenter .thumbnail': (e) ->
      $(e.target).find('.caption').fadeTo(200, 0.8)

    'mouseleave .thumbnail': (e) ->
      $(e.target).find('.caption').fadeTo(400, 0)
  )

  Template.photo.helpers(
    ownedPhoto: ->
      if Meteor.userId() == this.owner_id
        true
      else
        false
  )

  Template.photos.created = ->
    ## userId = any
    Session.setDefault("userId","")

  Template.photos.rendered = ->
    # Isotope fixed column layout
    $container = this.$('.thumbnail-container')
    $container.imagesLoaded ->
      $container.isotope
        itemSelector: '.thumbnail'
        masonry: 
          columnWidth: 310

  Template.photos.helpers(
    photos: ->
      if !!Session.get("userId")
        Photos.find {owner_id: Session.get("userId")},
          sort: 
            createdAt: -1
      else
        Photos.find {},
          sort: 
            createdAt: -1
  )   

  Template.photos.events(
    'click .my-photos': (e) ->
      Session.set("userId", Meteor.userId())

    'click .all-photos': (e) ->
      Session.set("userId", "")
  )

  Template.leftNav.helpers(
    profilePhoto: ->
      if Meteor.user().profile and Meteor.user().profile.profilePhoto
        Meteor.user().profile.profilePhoto
      else
        '/images/default_profile.jpg'
  )

  Template.leftNav.events(   
    'click .close-photos': (e) -> 
      $(document.getElementById('leftNav')).toggle()

    'click .add-photos': (e) ->
      uploads = _.map document.getElementById('photoFiles').files, (file) ->
        upload = new Slingshot.Upload("myFileUploads")
        console.log file

        # client side validation
        error = upload.validate(file)
        if error
          console.error error

        # toastr notification
        toastr.info(
          "Uploading photo: " + file.name
          "Upload in Progress"
        )

        # upload to s3
        upload.send file, (error, url) ->

          ## save photo to user document
          # Meteor.users.update Meteor.userId(), 
          #   $push: 
          #     "profile.photos": url

          if error 
            console.error error
          else 
            Photos.insert(
              accessControl: "public"
              dateCreated: new Date()
              owner_id: Meteor.userId()
              ownerUsername: Meteor.user().username
              title: file.name
              "url": url
            )
            toastr.success(
              "Upload successful!"
            )
        upload

        ## hide leftnav
        $(document.getElementById('leftNav')).toggle()
        
    'click .add-profilePhoto': (e) ->
      uploads = _.map document.getElementById('profilePhotoFile').files, (file) ->
        upload = new Slingshot.Upload("myFileUploads")
        console.log file

        # client side validation
        error = upload.validate(file)
        if error
          console.error error

        # toastr notification
        toastr.info(
          "Uploading photo: " + file.name
          "Upload in Progress"
        )

        # upload to s3
        upload.send file, (error, url) ->

          ## save photo to user document
          # Meteor.users.update Meteor.userId(), 
          #   $push: 
          #     "profile.photos": url

          if error 
            console.error error
          else 
            Meteor.users.update(
              _id: Meteor.userId()
            ,  
              $set: 
                'profile.profilePhoto': url
            )
            toastr.success(
              "Upload successful!"
            )
        upload
  )

  Template.albums.helpers(
    albums: ->
      if !!Session.get("userId")
        Photos.find {owner_id: Session.get("userId")},
          sort: 
            createdAt: -1
      else
        Photos.find {},
          sort: 
            createdAt: -1
  )  



if Meteor.isServer

  ## useraccount validation
  Meteor.methods 'userExists': (username) ->
    !!Meteor.users.findOne(username: username)

  Meteor.startup ->
