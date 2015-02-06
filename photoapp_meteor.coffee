Photos = new Mongo.Collection("photos")
Albums = new Mongo.Collection("albums")

Schemas = {}
Schemas.Photo = new SimpleSchema(
  title:
    type: String
    label: "Title"
    max: 200

  owner:
    type: String
    label: "Owner"
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

  Router.route '/', ->
    @render 'Welcome'

  Router.route '/photos', ->
    @render 'Photos'

  Router.route '/photo/edit/:_id', (->
    @render 'PhotoEdit',
      data: ->
        Photos.findOne _id: @params._id
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
    
  Template.leftNav.rendered = ->
    this.$('#navbar-left').mmenu(
      classes: "mm-white",
      footer:
        add: true,
        content: ""
        update: true
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
    
  Template.photo.rendered = ->
    ## attach fluidbox 
    ## docs@https://github.com/terrymun/Fluidbox
    $thumbnail = this.$('a[rel="fluidbox"]')
    # detect mobile by browser size
    isMobile = window.matchMedia("only screen and (max-width: 768px)").matches
    $thumbnail.fluidbox(
      isMobile: isMobile
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
      
    'click .thumbnail': (e) ->
      console.log ('clicked fluuidbox')
      console.log (this._id)
      Router.go "photo.edit",
        _id: this._id
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
              owner_id: Meteor.userId()
              "url": url
              createdAt: new Date()
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
  Meteor.startup ->
