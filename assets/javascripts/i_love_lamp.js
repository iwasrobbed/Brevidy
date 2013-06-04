/*!
*
* Brevidy jQuery effects, validations, and other stuff
*
* Think you can improve this code?  E-mail us at:  jobs@brevidy.com
*
*/

$(document).ready(function(){
  
// -----
// SETUP
// -----

   // Add global data to every AJAX request (if necessary)
   brevidy.setup_ajax_data = function() {
     var global_token = $('input[name="channel_token"]');
     if (global_token) { $.ajaxSetup({ data: { 'channel_token': global_token.val() }})}
   }; brevidy.setup_ajax_data();
  
// -------------
// GENERIC STUFF
// -------------

   // Prevents click jump on certain links
   $('.prevent-jump').live('click', function(e) {
     e.preventDefault();
   });

  
// ---------------
// DROP DOWN MENUS
// ---------------
  
    // Show the menus on hover
    $('.dropdown').live('mouseenter mouseleave', function(event) { 
			if (event.type == 'mouseenter') {
  		  $(this).addClass('open').children('.dropdown-menu').show();
  		} else {
  		 $(this).removeClass('open').children('.dropdown-menu').fadeOut('fast');
  		}
		});
		
		// Hide all menus if they click anywhere
		$('html').click(function() {
		  $('.dropdown').removeClass('open').children('.dropdown-menu').fadeOut('fast');
		});
		
		
// -------------
// AJAX SPINNERS
// -------------
	  
	  // Sets up ajax spinner near video controls
	  brevidy.setup_video_ajax_spinner = function(bound_object) {
	    var idType = 'data-video-id';
			var id = bound_object.attr(idType);
			
		  brevidy.show_video_ajax_spinner(id);
			bound_object.bind("ajaxStop", function(){
			  brevidy.hide_video_ajax_spinner(id);
			});
		}
		
		// Shows the video ajax spinner for custom ajax calls
		brevidy.show_video_ajax_spinner = function(video_id) {
		  var idType = 'data-video-id';
		  $('li.ajax-animation['+idType+'='+video_id+']').css('display', 'inline');
		}
		
		// Hides the video ajax spinner for custom ajax calls
		brevidy.hide_video_ajax_spinner = function(video_id) {
		  var idType = 'data-video-id';
		  $('li.ajax-animation['+idType+'='+video_id+']').css('display', 'none');
		}
		
		// Attach ajax spinner to generic links
		$('.add-to-channel-link, .remove-tag, .view-all-badges, .thumbnail-and-badges .thumbnail, p.view-all-badges a').live('click',function() {
      brevidy.setup_video_ajax_spinner($(this));
		});	

// ------------------
// EXPANDING SECTIONS
// ------------------
    $('.expandable').expander({
      slicePoint: 300,
      expandPrefix: '... ',
      expandText: 'Read more',
      preserveWords: false,
      userCollapse: false,
      widow: 0
    });
    
    
// ----------------------
// CHARACTER INPUT LIMITS
// ----------------------

	// Calculates how many characters are in a textarea to limit user input 
	// Works for regular input as well as copy & pasting test
	// Must match format: <textarea maxlength="250"></textarea> or <input type='text' maxlength="250">
	// With an optional field for displaying how many characters are left: <span class="chars-remaining">250 characters</span>
		
		$('input[maxlength], textarea[maxlength]').limitMaxlength({
			onEdit: onEditCallback
		});
		
		
// ----------------
// TWIPSY TOOL TIPS
// ----------------

    // Instantiates standard twipsy tooltip objects with default settings
    $('[rel=twipsy], .tooltip').twipsy();
    
		// Retrieves the icon class (assume class format 'badgeSomeBadgeNameHere' where 'badge' is followed by some string of letters)
		brevidy.get_badge_icon_class_name = function(class_array) {
		  var badgeIcon = false;
	  	$.each(class_array, function(index, item) {
				if (item.match(/^badge[A-Za-z]+$/)) {
				  // they are hovering over a small badge (one to give to a video)
					badgeIcon = item;
				} else if (item.match(/^badge[A-Za-z]+_Large$/)) {
				  // they are hovering over a large badge (one already given to a video)
					item = item.replace('_Large', '');
					badgeIcon = item;
				}
	  	});
		  return badgeIcon;
		};
		
		// Provides a custom template for the tooltip contents
		brevidy.custom_badge_title = function(title, badge) {
			title = '<div class="title"><i class="' + badge + '_Preview' + '"></i><p>'+ title +'</p></div>';
			return title;
		}
		
		// Set up custom tooltips for showing badges
		$('.tooltip-with-icon').twipsy({ html: true, title:
			function() {
				// find which type of icon (regular or large) was hovered
				var currentIconClassArray = $(this).attr('class').split(/\s+/);
				var currentBadgeIcon = brevidy.get_badge_icon_class_name(currentIconClassArray);
			
				return brevidy.custom_badge_title(this.getAttribute('data-original-title'), currentBadgeIcon);
			}
		});


// ----
// TABS
// ----
    
    // Instantiates tabbed areas
    $('.tabs').tabs();


// -------------
// MODAL DIALOGS
// -------------
    
    // Creates and shows a custom modal dialog
    brevidy.custom_dialog = function(html_template) {
      if ($('#brevidy-modal').length != 0) {
        // There is already a modal showing so do nothing
      } else {  
        // Append the modal
        $('body').append(html_template);
      
        // Show the new modal
        $('#brevidy-modal').modal({ show : true,
                                    backdrop: 'static',
                                    keyboard: true });
      }
    }
    
    // Creates and shows a standard modal dialog
    brevidy.dialog = function(title, message, dialog_type) {
      if ($('#brevidy-modal').length != 0) {
        // There is already a modal showing so do nothing
      } else {
        // There is not another modal showing so let's create one
        
        // See if it needs any CSS changes for an Error dialog
        if (dialog_type == 'error') { var extra_css = 'error' }
      
        // Setup a template to use
        var html_template = '<div id="brevidy-modal" class="modal hide"> \
                               <div class="modal-header '+ extra_css +'"> \
                                 <h3>'+ title +'</h3> \
                               </div> \
                               <div class="modal-body"> \
                                 <p>'+ message +'</p> \
                               </div> \
                               <div class="modal-footer"> \
                                 <a href="#" class="modal-okay-btn btn">Okay</a> \
                               </div> \
                             </div>';
                           
      
        // Append the modal
        $('body').append(html_template);
      
        // Show the new modal
        $('#brevidy-modal').modal({ show : true,
                                    backdrop: 'static',
                                    keyboard: true });
      }
    }
    
    // Creates and shows a confirmation modal dialog
    brevidy.confirmation_dialog = function(message, confirm_type, action_button_clicked) {
      if ($('#brevidy-modal').length != 0) {
        // There is already a modal showing so do nothing
      } else {
        // There is not another modal showing so let's create one

        var button_type = (confirm_type == 'Delete' || confirm_type == 'Remove' || confirm_type == 'Block') ? 'danger' : 'primary';
        var buttons = '<a href="#" class="modal-confirm-btn btn '+ button_type +'" >'+ confirm_type +'</a> \
                       <a href="#" class="modal-cancel-btn btn secondary">Cancel</a>';
        
        // Setup a template to use
        var html_template = '<div id="brevidy-modal" class="modal hide"> \
                               <div class="modal-header"> \
                                 <h3>Are you sure?</h3> \
                               </div> \
                               <div class="modal-body"> \
                                 <p>'+ message +'</p> \
                               </div> \
                               <div class="modal-footer">' +
                                 buttons +
                               '</div> \
                             </div>';
                           
      
        // Append the modal
        $('body').append(html_template);
      
        // Show the new modal
        $('#brevidy-modal').modal({ show : true,
                                    backdrop: 'static',
                                    keyboard: true });
        
        // Create a callback function
        if(action_button_clicked) {
		      $('.modal-confirm-btn').click(action_button_clicked);
		    }
      }
    }
    
    // Shows a normal message modal dialog with an Okay button
    // Requires these attributes to be set on the link:
    //   data-modal-title
    //   data-modal-message
    //
    $('a.show-msg-modal').live('click', function () {
      var title = $(this).attr('data-modal-title'),
          message = $(this).attr('data-modal-message');
      
      brevidy.dialog(title, message, "message");
      return false;
    });
    
    // Hides the modal dialog when one of the buttons are pressed
    $('a.modal-cancel-btn, a.modal-okay-btn').live('click', function() {
      $('#brevidy-modal').modal('hide').remove();
      return false;
    });
    
    // Hides the modal dialog when the "Action" button is pressed
    $('a.modal-confirm-btn').live('click', function() {
      $('#brevidy-modal').modal('hide').remove();
      return false;
    });
    
    // Handles AJAX errors by showing the user a modal dialog
    //   objectType is a string containing "comment", "badge", etc.
    //   xhr is the object returned upon an AJAX error
    brevidy.handle_ajax_error = function(objectType, xhr) {
			if (typeof objectType == 'undefined') { objectType = "item" };

			// Try to parse the response text
			try { var responseText = jQuery.parseJSON(xhr.responseText); } catch(e) { var responseText = null; }

			if (xhr.status == 404) {
				if (responseText !== null) { var responseMsg = responseText.error; } else { var responseMsg = 'That '+ objectType +' could not be found or you do not have the proper access for it'; }
			} else if (xhr.status == 422 || 401) {
				if (responseText !== null) { var responseMsg = responseText.error; }
			}
			if (typeof responseMsg == 'undefined') { responseMsg = 'There was an unknown error or the request timed out.  Please try again later'; }

			brevidy.dialog('Error', responseMsg, 'error');
		};


// --------
// POPOVERS
// --------

    // Instantiate the popovers w/ options
    $('.featured-popover').popover({ placement : 'below' });
    

// -------------
// SCROLL TO TOP
// -------------
    
    // Hide the scroll to top area
    $('#back-to-top').hide();
    
    // Set up a variable so we don't attach directly to the window's scroll callback
    var brevidyWindowDidScroll = false;
		$(window).scroll(function () {
		  brevidyWindowDidScroll = true;
		});
		
    // Show/Hide the "back to top" area based on scroll location (only check ever 250ms)
		setInterval(function () {
		  if (brevidyWindowDidScroll) {
        brevidyWindowDidScroll = false;
        if ($(window).scrollTop() > 100) { $('#back-to-top').fadeIn(); } else { $('#back-to-top').fadeOut(); }
      }
		}, 250);

		// Scroll to the top
		$('#back-to-top a').click(function () {
			$.smoothScroll({
        scrollTarget: '#top',
        speed: 1000
      });
			return false;
		});


// -------
// SIGN UP
// -------

		// Validate the signup form information before sending it server-side
		$(':submit[name="signup"]').click(function() {
		
			// store the fields to be validated
			var username = $(':text[id="signupUsername"]');
			var username_completed = username.val().trim().length;
			var name = $(':text[id="signupName"]');
			var name_completed = name.val().trim().length;
			var email = $(':text[id="signupEmail"]');
			var email_completed = email.val().trim().length;
			var password = $(':password[id="signupPassword"]');
			var password_completed = password.val().trim().length;
			var birthday_month = $('select[id="signupBirthdayMonth"]');
			var birthday_month_not_selected = $('option#signupChooseMonth:selected').length;
			var birthday_day = $('select[id="signupBirthdayDay"]');
			var birthday_day_not_selected = $('option#signupChooseDay:selected').length;
			var birthday_year = $('select[id="signupBirthdayYear"]');
			var birthday_year_not_selected = $('option#signupChooseYear:selected').length;
		
			// create a bool to know when the form is ready to submit
			var form_is_ready;
			
			// make sure all fields are filled out
			if (!username_completed || !name_completed || !email_completed || !password_completed || 
			    birthday_month_not_selected || birthday_day_not_selected || birthday_year_not_selected) {
				
				$('.formErrorField.js-validate').slideUp("fast", function () {
						$(this).html('Please fill out the entire form.').slideDown("fast");
					});
				
			} else if (password.val().trim().length < 6) {
				
				$('.formErrorField.js-validate').slideUp("fast", function () {
						$(this).html('Password must be longer than 6 characters.').slideDown("fast");
					});
				
			} else { 
				$('.formErrorField.js-validate').slideUp("fast");
				form_is_ready = 1; 
			}
		
			// prevent form from submitting if any of the criteria was not met
			if (!form_is_ready) {
				return false;
			}
		});


// ----------
// TOP BANNER
// ----------

    // Shows and hides the change banner button if present
    $('.top-banner').mouseenter(function() {
  		$(this).children('a').css('display', 'block');
  	}).mouseleave(function() {
  		$(this).children('a').css('display', 'none');
  	});
  	

// -------------------
// VIDEO POST CONTROLS
// -------------------
  
    // Shows and hides the settings icon on a video post
    $('.video-post').live('mouseenter mouseleave', function(event) { 
			if (event.type == 'mouseenter') {
  		  $(this).children('.row.heading').children('ul.settings-menu').show();
	    } else {
  		  $(this).children('.row.heading').children('ul.settings-menu').fadeOut("fast");
  		}
  	});
    
    // Handles changing opacity of icons next to control links
    $('.add-to-channel-link, .badge-link, .comment-link, .share-link, .tag-link').live('mouseenter mouseleave', function(event) { 
			if (event.type == 'mouseenter') {
  		  $(this).children('img').css('opacity', '1.0');
  	  } else {
  		  $(this).children('img').css('opacity', '.75');
  		}
  	});
		
	  // Shows the badge area for a video post that has no badges yet
		$('.give-first-badge').live('click', function() {
			var idType = 'data-video-id';
			var id = $(this).attr(idType);
			var badgesArea = $('.badges-area['+idType+'='+id+']');
			var badgesArrow = $('.badge-arrow['+idType+'='+id+']');
			
			if (badgesArea.is(":visible")) {
				badgesArrow.fadeOut("fast", function() {
					$(this).fadeIn("fast");
				});
				badgesArea.fadeOut("fast", function() {
					$(this).fadeIn("fast");
				});
			} else {
				badgesArea.show();
				badgesArrow.show();
				$('.comments-area['+idType+'='+id+']').hide();
				$('.comment-arrow['+idType+'='+id+']').hide();
				$('.share-area['+idType+'='+id+']').hide();
				$('.share-arrow['+idType+'='+id+']').hide();
				$('.tags-area['+idType+'='+id+']').hide();
				$('.tag-arrow['+idType+'='+id+']').hide();
			}
		
			return false;
		});
		
	  // Show badges area
		$('.badge-link').live('click', function() {
		  var idType = 'data-video-id';
			var id = $(this).attr(idType);
		
			$('.badges-area['+idType+'='+id+']').fadeToggle(100);
			$('.badge-arrow['+idType+'='+id+']').fadeToggle(100);
			$('.comments-area['+idType+'='+id+']').hide();
			$('.comment-arrow['+idType+'='+id+']').hide();
			$('.share-area['+idType+'='+id+']').hide();
			$('.share-arrow['+idType+'='+id+']').hide();
			$('.tags-area['+idType+'='+id+']').hide();
			$('.tag-arrow['+idType+'='+id+']').hide();
			return false;
		});
		
		// Show comments area
		$('.comment-link').live('click', function() {
		  var idType = 'data-video-id';
			var id = $(this).attr(idType);
		
			$('.badges-area['+idType+'='+id+']').hide();
			$('.badge-arrow['+idType+'='+id+']').hide();
			$('.comments-area['+idType+'='+id+']').fadeToggle(100);
			$('.comment-arrow['+idType+'='+id+']').fadeToggle(100);
			$('.share-area['+idType+'='+id+']').hide();
			$('.share-arrow['+idType+'='+id+']').hide();
			$('.tags-area['+idType+'='+id+']').hide();
			$('.tag-arrow['+idType+'='+id+']').hide();
			
			// set focus to textarea to reduce # of clicks for the user
			$('.comments-area['+idType+'='+id+'] textarea').select();
			
			return false;
		});
		
		// Show sharing area
		$('.share-link').live('click', function() {
		  var idType = 'data-video-id';
			var id = $(this).attr(idType);
		
			$('.badges-area['+idType+'='+id+']').hide();
			$('.badge-arrow['+idType+'='+id+']').hide();
			$('.comments-area['+idType+'='+id+']').hide();
			$('.comment-arrow['+idType+'='+id+']').hide();
			$('.share-area['+idType+'='+id+']').fadeToggle(100);
			$('.share-arrow['+idType+'='+id+']').fadeToggle(100);
			$('.tags-area['+idType+'='+id+']').hide();
			$('.tag-arrow['+idType+'='+id+']').hide();
			
			// set focus to public link (if there is one) for copy/paste
			$('.share-area['+idType+'='+id+'] .share-content .public-link').children('input[type=text]').select();

			return false;
		});
		
		// Show tags area
		$('.tag-link').live('click', function() {
		  var idType = 'data-video-id';
			var id = $(this).attr(idType);
		
			$('.badges-area['+idType+'='+id+']').hide();
			$('.badge-arrow['+idType+'='+id+']').hide();
			$('.comments-area['+idType+'='+id+']').hide();
			$('.comment-arrow['+idType+'='+id+']').hide();
			$('.share-area['+idType+'='+id+']').hide();
			$('.share-arrow['+idType+'='+id+']').hide();
			$('.tags-area['+idType+'='+id+']').fadeToggle(100);
			$('.tag-arrow['+idType+'='+id+']').fadeToggle(100);
			return false;
		});
		
		// Handles deleting a video
		$('.delete-video').live('click', function() {		
		  var idType = 'data-video-id';
			var id = $(this).attr(idType);
			var video_path = $(this).attr('href');
	
		  brevidy.confirmation_dialog('You are about to delete this video which will also delete all comments and badges associated with the video.  This cannot be undone.', 'Delete',
	    	function() {
  				// show the ajax spinner
  				brevidy.show_video_ajax_spinner(id);

  				$.ajax({
  					data: { '_method': 'DELETE' },
  					type: 'POST',
  					url: video_path,
  		  		success: function (json) {
  						// remove the video post
  						$('.video-post['+idType+'='+id+']').fadeOut('fast', function() {
  					    $(this).remove();
  					  });
  					},
  					error: function (response) {
  					  brevidy.hide_video_ajax_spinner(id);
  						brevidy.handle_ajax_error('video', response);
  					}
  				});
			  });
			
			return false;
		});
		
// --------------
// BADGE HANDLING		
// --------------
  
    // Handles giving a badge
    $('.give-a-badge').live('click', function() {
			
			var $that = $(this);
			var idType = 'data-badge-type';
			var id = $that.attr(idType);
			var badges_path = $that.attr('href');
			var video_id = $(this).attr('data-video-id');

			brevidy.show_video_ajax_spinner(video_id);
			
			$.ajax({
				data: { 'badge_type':id },
				type: 'POST',
				url: badges_path,
				success: function (json) {
					var foundBadge = false;
					var idTypeUser = 'data-user-id';
					var idTypeVideo = 'data-video-id';
					var idVideo = json.video_id;
					var currentListOfBadges = $('.show-badges['+idTypeVideo+'='+idVideo+'] .badges li');
					var currentBadgeTypesCount = currentListOfBadges.size();
					
					// Fade out the icon and replace the tooltip class
					$that.fadeOut(1, function() {
						$(this).after(json.unbadge);
						$(this).remove();
					});
					
					// Remove old tipsy tooltip from body of the doc
					$('.twipsy').remove();

					// Place badge under the video thumbnail
					if (json.total_video_badges == 1) {
					  
						// Give the first badge
						$('.show-badges['+idTypeVideo+'='+idVideo+']').html('<div class="badges" data-video-id="'+ idVideo +'"><ul>'+ json.html +'</ul></div>');
						$('.show-badges['+idTypeVideo+'='+idVideo+'] ul li:first').css({opacity: '0.0'}).animate({opacity: '1.0'}, 500);

					} else {
					  
						// See if the badge type already is shown on the page for this video
						$('.show-badges['+idTypeVideo+'='+idVideo+'] li').each(function (index, value) {
							var $that = $(this);
							var existingBadge = $that.attr(idType);
							if (id == existingBadge) { foundBadge = $that; }
						});
            
            // The badge is already showing on the screen so replace it
            if (foundBadge) {
							foundBadge.fadeOut('fast', function() { 
							  $(this).remove();	
							  $('.show-badges['+idTypeVideo+'='+idVideo+'] ul').prepend(json.html);
						    $('.show-badges['+idTypeVideo+'='+idVideo+'] ul li:first').css({opacity: '0.0'}).animate({opacity: '1.0'}, 500);
							});
							
						// Badge wasn't showing on the screen
            } else {              
              // Check if 5+ badges are showing
              if (currentBadgeTypesCount >= 5) {
  							$('.show-badges['+idTypeVideo+'='+idVideo+'] ul li').eq(4).fadeOut("fast", function() { 
  							  $(this).remove(); 
  							  $('.show-badges['+idTypeVideo+'='+idVideo+'] ul').prepend(json.html);
						      $('.show-badges['+idTypeVideo+'='+idVideo+'] ul li:first').css({opacity: '0.0'}).animate({opacity: '1.0'}, 500);
  							});
  						} else {
  						  $('.show-badges['+idTypeVideo+'='+idVideo+'] ul').prepend(json.html);
						    $('.show-badges['+idTypeVideo+'='+idVideo+'] ul li:first').css({opacity: '0.0'}).animate({opacity: '1.0'}, 500);
  						}
            }

					}
					// Remove the "no badges given yet" text
					$('p.no-badges-given-yet['+idTypeVideo+'='+idVideo+']').remove();
					
					// Add the correct 'View All Badges' link 
					$('p.view-all-badges['+idTypeVideo+'='+idVideo+']').remove();
					$('.show-badges['+idTypeVideo+'='+idVideo+'] .badges').after('<p class="view-all-badges"  data-video-id="'+ idVideo +'">'+ json.view_all_badges_link +'</p>');
				  
				  brevidy.hide_video_ajax_spinner(video_id);
				},
				error: function (response) {
				  brevidy.hide_video_ajax_spinner(video_id);
					brevidy.handle_ajax_error("badge", response);
				}
			});
			
			return false;
		});
		
	  // Handles removing badges	
		$('.unbadge').live('click', function() {
			var $that = $(this);
			var unbadge_path = $that.attr('href');
			var idTypeBadge = 'data-badge-id';
			var idBadge = $that.attr(idTypeBadge);
			var video_id = $(this).attr('data-video-id');

			brevidy.show_video_ajax_spinner(video_id);
			
			$.ajax({
				data: { '_method': 'DELETE',},
				dataType: 'json',
				type: 'POST',
				url: unbadge_path + '/' + idBadge,
	  		success: function (json) {
					var idTypeUser = 'data-user-id';
					var idTypeVideo = 'data-video-id';
					var idVideo = json.video_id;
					var idType = 'data-badge-type';
					var id = $that.attr(idType);
					
					// Remove old tooltip
					$('.twipsy').remove();
					
					// Fade out the icon and replace the tooltip class
					$that.fadeOut(1, function() {
						$(this).after(json.give_a_badge);
						$(this).remove();
					});
					
					// Update badge counts across page
					$('.show-badges['+idTypeVideo+'='+idVideo+'] li['+idType+'='+id+'] span').text(json.this_badge_count);
					
					
					// If its the last one of it's kind, remove it
					if (json.this_badge_count == 0) {
						$('.show-badges['+idTypeVideo+'='+idVideo+'] li['+idType+'='+id+']').fadeOut('fast', function() {
							$(this).remove();
						});
					}
					
					if (json.total_video_badges == 0) {
					  // If its the last badge, after we unbadged it, show a message stating that
						$('.show-badges['+idTypeVideo+'='+idVideo+'] .badges, p.view-all-badges['+idTypeVideo+'='+idVideo+']').fadeOut('fast', function() {
							$(this).remove();
							$('.show-badges['+idTypeVideo+'='+idVideo+']').html('<p class="no-badges-given-yet">No badges given yet.  <a class="give-first-badge" data-video-id="'+ idVideo +'" href="#">Give one!</a></p>');
						});
					} else {
						// If there are still more badges showing, add the correct 'View All Badges' link 
					  $('p.view-all-badges['+idTypeVideo+'='+idVideo+']').remove();
					  $('.show-badges['+idTypeVideo+'='+idVideo+'] .badges').after('<p class="view-all-badges"  data-video-id="'+ idVideo +'">'+ json.view_all_badges_link +'</p>');
					}
					
					brevidy.hide_video_ajax_spinner(video_id);
				},
				error: function (response) {
				  brevidy.hide_video_ajax_spinner(video_id);
					brevidy.handle_ajax_error("badge", response);
				}
			});
			
			return false;
		});


// ----------------
// CHANNEL HANDLING
// ----------------

    // Setup ajax spinner for updating channel name
    $('#update-channel-name input[type=submit]').live('click', function() {
      $(this).parent().siblings('.ajax-animation').fadeIn('fast');
    });
    $('#update-channel-name').live('ajax:success', function(data, json, response) {
      $(this).siblings('.ajax-animation').hide();
      $(this).siblings('.green-checkmark').fadeIn('slow').fadeOut('1000');
    });
    $('#update-channel-name').live('ajax:error', function(data, xhr, response){
      $(this).siblings('.ajax-animation').hide();
      brevidy.handle_ajax_error("channel", xhr);
    });
    
    // Toggles button classes for privacy settings
    $('#toggle-channel-privacy').live('ajax:success', function(data, json, response) {
      console.log($(this).attr('href'));
      var $that = $(this);
      if ($that.hasClass('success')) {
        console.log('turning off privacy');
        $that.attr('href', json.new_link).removeClass('success').text('No');
        $('.private-channel-link').fadeOut('fast');
      } else {
        console.log('turning on privacy');
        $that.attr('href', json.new_link).addClass('success').text('Yes');
        $('.private-channel-link').fadeIn('fast');
      }
    });
    
    // Handles AJAX errors
    $('#toggle-channel-privacy').live('ajax:error', function(data, xhr, response) {
			brevidy.handle_ajax_error("channel", xhr);
		});
		
		$('.subscribe').live('ajax:success', function(data, json, response) {
		  if (json.requesting_permission) {
		    brevidy.dialog("Requesting Access", "We have sent an email on your behalf requesting access to this channel.  Please be patient while they respond to this request.", "message");
		  } else {
		    if ($(this).hasClass('small')) {
		      $(this).closest('.pull-right').html(json.button);
		    } else {
		      $(this).closest('.button-area').html(json.button); 
		    }
		  }
		});
		$('.unsubscribe').live('ajax:success', function(data, json, response) {
		  if ($(this).hasClass('small')) {
		    $(this).closest('.pull-right').html(json.button);
		  } else {
  		  var button_area = $(this).closest('.button-area');
  		  button_area.html(json.button);
  		  if (json.is_private) {
    		  button_area.siblings('.channel-thumbnail-area').fadeOut('fast', function() {
    		    $(this).before(json.private_area_message);
    		    $(this).remove();
    		  });
    		}
    	}
		});
		$('.subscribe, .unsubscribe').live('ajax:error', function(data, xhr, response) {
			brevidy.handle_ajax_error("channel", xhr);
		});
		
		// Shows handle delete area
		$('.delete-channel-area .show-delete-area').click(function() {
		  $(this).remove();
		  $('.alert-message').slideDown('fast');
		  return false;
		});
		
		// Handles deleting a channel
		$('.delete-channel').live('click', function() {		
			var channel_path = $(this).attr('href');
	
		  brevidy.confirmation_dialog('You are about to delete this channel which will also delete all videos, comments, badges, and subscribers associated with this channel.  This cannot be undone.', 'Delete',
	    	function() {
  				$.ajax({
  					data: { '_method': 'DELETE' },
  					type: 'POST',
  					url: channel_path,
  					error: function (response) {
  						brevidy.handle_ajax_error('channel', response);
  					}
  				});
			});
			
			return false;
		});
		
		// Removes a subscriber
		$('.remove-subscriber').live('click', function() {		
			var $that = $(this);
			var removal_path = $that.attr('href');
	
		  brevidy.confirmation_dialog('You are about to remove this person from your subscribers.', 'Remove',
	    	function() {
  				$.ajax({
  					data: { '_method': 'DELETE' },
  					type: 'POST',
  					url: removal_path,
  					success: function (json) {
  					  $that.closest('li.zebra-striped').fadeOut('fast', function() {
		            $(this).remove();
		          });
  					},
  					error: function (response) {
  						brevidy.handle_ajax_error("subscriber", xhr);
  					}
  				});
			});
			
			return false;
		});
		
		// Handles blocking a user
		$('.block-user').live('click', function() {
			var $that = $(this);
			var block_path = $that.attr('href');
	
		  brevidy.confirmation_dialog('You are about to block this user which will unsubscribe them from all of your channels and prevent them from viewing your content in the future.', 'Block',
	    	function() {
  				$.ajax({
  					data: { '_method': 'DELETE' },
  					type: 'POST',
  					url: block_path,
  					success: function (json) {
  					  $that.closest('li.zebra-striped').fadeOut('fast', function() {
		            $(this).remove();
		          });
  					},
  					error: function (response) {
  						brevidy.handle_ajax_error("user", xhr);
  					}
  				});
			});
			
			return false;
		});


// ----------------
// COMMENT HANDLING
// ----------------

	  // Expands the comment textarea on focus
		$('.comment-box textarea').live('focus', function() {
			var idType = 'data-video-id';
			var id = $(this).attr(idType);
			
			$(this).animate({'height': '35px',}, 'fast' );
			$('.comment-box .button-wrapper['+idType+'='+id+']').slideDown('fast');
		});	
	
    // Allows user to submit the comment using the enter key
	  $('.comment-box textarea').live('keydown', function(event) {
      if(event.keyCode == '13') {
        comment_button = $(this).siblings('.button-wrapper').children('.btn');
        comment_button.submit();
        brevidy.setup_video_ajax_spinner($(this));
        
        return false;
      }
    });
    
    // Show ajax spinner when comment button is pressed
    $('.comment-box input.btn').live('click', function() {
		  brevidy.setup_video_ajax_spinner($(this));
		});
		
    // Description: Shows all comments when user wants to expand them
  	$('a.show-all-comments').live('click', function() {
  		var $that = $(this);
  		var idType = 'data-video-id';
  		var id = $that.attr(idType);
		
  		$that.parent().fadeOut('fast', function() {
  		  $('li.hidden-comment['+idType+'='+id+']').fadeIn("fast");
  		  $that.remove();
  		});
		
  		return false;
  	});
  	
  	// Append a comment to the end of the comments section for a particular video post
		$('.post-new-comment').live('ajax:success', function(data, json, response) {
			var idType = 'data-video-id';
			var id = json.video_id;
			var $that = $(this);
			
			// fade in the new comment
			var comments_list = $('.comments-area['+idType+'='+id+'] ul.comments-list');
			comments_list.append(json.html);
			comments_list.children('li:last').hide().fadeIn(250);
			
			// update the comments count (if there is one)
			$('li.show-all-comments a['+idType+'='+id+']').text('Show all ' + json.comments_count + ' comments');
			
			// clear the text area and blur it
			$('.comment-box textarea['+idType+'='+id+']').val('').blur();
		});
		
		// Shows the delete icon if applicable
		$('.comments-list li').live('mouseenter mouseleave', function(event) {
  		if (event.type == 'mouseenter') {
  		  $(this).children('.delete-comment').show();
  		} else {
  		  $(this).children('.delete-comment').hide();
  		}
  	});
  	
  	// Changes opacity on icon during hover
  	$('.delete-comment').live('mouseenter mouseleave', function(event) {
  		if (event.type == 'mouseenter') {
  		  $(this).css('opacity', '1.0');
  		} else {
  		  $(this).css('opacity', '0.5');
  		}
  	});
		
		// Removes comments after deletion
		$('.delete-comment').live('ajax:success', function(data, json, response) {
		  $('.twipsy').remove();
		  $(this).closest('li').fadeOut('fast', function() {
		    $(this).remove();
		  });
	  });
	  
	  // Handles AJAX errors
	  $('.post-new-comment, .delete-comment').live('ajax:error', function(data, xhr, response) {
			brevidy.handle_ajax_error("comment", xhr);
		});
	

// --------------
// SHARE HANDLING
// --------------

    // Shows the social sharing options for a video
    $('a.share-socially').live('click', function() {
      $(this).addClass('lighten-to-blue').siblings().filter('.lighten-to-blue').removeClass('lighten-to-blue');
      
      $(this).siblings('.public-link, .embed-code, .email-form').filter(':visible').fadeOut('fast', function() {
        $(this).siblings('.social-sharing').fadeIn('fast');
      });
      
      return false;
    });
    
    // Shows the public link to a video
    $('a.link-to-video').live('click', function() {
      $(this).addClass('lighten-to-blue').siblings().filter('.lighten-to-blue').removeClass('lighten-to-blue');
      
      $(this).siblings('.social-sharing, .embed-code, .email-form').filter(':visible').fadeOut('fast', function() {
        $(this).siblings('.public-link').fadeIn('fast').children('input[type=text]').select();
      });
      
      return false;
    });
    
    // Shows the embed code for a video 
    $('a.embed-video').live('click', function() {
      $(this).addClass('lighten-to-blue').siblings().filter('.lighten-to-blue').removeClass('lighten-to-blue');
      
      $(this).siblings('.social-sharing, .public-link, .email-form').filter(':visible').fadeOut('fast', function() {
        $(this).siblings('.embed-code').fadeIn('fast').children('textarea').select();
      });
      
      return false;
    });
    
    // Shows the form to email out a video
    $('a.email-video').live('click', function() {
      $(this).addClass('lighten-to-blue').siblings().filter('.lighten-to-blue').removeClass('lighten-to-blue');
      
      $(this).siblings('.social-sharing, .public-link, .embed-code').filter(':visible').fadeOut('fast', function() {
        $(this).siblings('.email-form').fadeIn('fast').children('input[type=text]').select();
      });
      
      return false;
    }); 

    // Handle ajax errors or success for sharing a video via email
    $('.share-via-email').live('ajax:success', function(data, json, response) {
			brevidy.dialog('Yay!!!', json.message, 'message');
			$(this).children('input[name="recipient_email"], textarea[name="personal_message"]').val('');
		});
    $('.share-via-email').live('ajax:error', function(data, xhr, response) {
			brevidy.handle_ajax_error('invitation', xhr);
		});


// -------------
// TAGS HANDLING
// -------------

	  // Handles the removal of tags
		$('a.remove-tag').live('ajax:success', function(data, json, response) {
			$that = $(this);
			var idType = 'data-video-id';
			var id = json.video_id;
			
			$('.twipsy').remove();
			
			$that.parent().fadeOut("fast", function() {
				$that.parent().remove();
				if (json.tags_count == 0) {
					$('.tags-area['+idType+'='+id+']').html('<p class="no-content-msg"><i>There are currently no tags organizing this video.</i></p>');
				}
			});
		});
		$('a.remove-tag').live('ajax:error', function(data, xhr, response) {
			brevidy.handle_ajax_error("tag", xhr);
		});
  
// ---------------------------
// VIDEO PLAYER CLICK HANDLING
// ---------------------------

	  // Handles fade effects for expanding/collapsing a video post
		$('.thumbnail-and-badges .thumbnail').live('click', function() {
			var idType = 'data-video-id';
			var id = $(this).attr(idType);
			var video_path = $(this).attr('data-video-path');

      if (video_path.length != 0) {
  			$.ajax({
          dataType: 'json',
  				type: 'GET',
  				url: video_path,
  				success: function(json) {
  				  // place the embed code
  				  $('#brevidy-player-'+id).html(json.html)
				  
  				  // fade in the player
  				  $('.thumbnail['+idType+'='+id+']').fadeOut(150, function() {
      				$('.player-area['+idType+'='+id+']').fadeIn(100, function () {
    				  
      				  // Scroll the player into view
      				  $.smoothScroll({
                  offset: -50,
                  scrollTarget: '.video-post['+idType+'='+id+']',
                  speed: 500
                });
    				  
      				});
      			});
      			
      			// close all the other open players
    			  var open_players = $('.player-area').filter(':visible').not('.player-area['+idType+'='+id+']');
    			  $.each(open_players, function (index, open_player) {
    			    brevidy.collapse_player($(this).attr('data-video-id'));
    			  });
  				},
  				error: function(response) {
  				  brevidy.handle_ajax_error('video', response);
          }
  			});
			} else {
			  brevidy.hide_video_ajax_spinner(id);
			}

			return false;
		});
		
		// Collapses the video player upon click
		$('.collapse-player-controls a').live('click', function() {
		  // collapse the player  
			brevidy.collapse_player($(this).attr('data-video-id'));
			return false;
		});
		
		// Collapses a given video player after the user is done with it
		brevidy.collapse_player = function(video_id) {
		  var idType = 'data-video-id';
			$('.player-area['+idType+'='+video_id+']').fadeOut(5, function() {  
			  // reset it if it's a brevidy player
			  if (jwplayer('brevidy-player-'+video_id)) { jwplayer('brevidy-player-'+video_id).remove(); }
			  
			  // remove the player from the DOM
			  $('#brevidy-player-'+video_id).html('');
			  
			  // fade in description 
				$('.thumbnail['+idType+'='+video_id+']').fadeIn(5);
			});
		};
		
		
// --------
// PROFILES
// --------
	
		// An array with class names for objects to edit
		brevidy.profileCategories = ['website', 'bio','interests','favorite_music','favorite_movies','favorite_books',
			                           'favorite_foods','favorite_people','things_i_could_live_without',
			                           'one_thing_i_would_change_in_the_world','quotes_to_live_by'];
	
		// Parses current profile information and populates editing fields
		$('#edit-profile').click(function () {
			$(this).hide();
			$('#save-profile').show();
			$('#cancel-profile').show();
			
			// iterate through categories, set the textarea text and show/hide
			$.each(brevidy.profileCategories, function (index, value) {
				if ($('.profile-content div.' + value).text().trim().toLowerCase() == 'none') {
					$('.profile-content textarea.' + value).val('');
				}
				$('.profile-content div.' + value).hide();
				$('.profile-content textarea.' + value).show();
			});
		
			return false;
		});
		
		// set up ajax spinner
		$('#save-profile')
			.ajaxStart(function() {
			    $('.profile-buttons .ajax-animation').show();
			})
			.ajaxStop(function() {
		        $('.profile-buttons .ajax-animation').hide();
		    });
	
		// Grabs editing fields and validates/saves the information to their profile
		$('#save-profile').click(function () {
			var $that = $(this);
			var profile = {};
			var profile_path = $that.attr('href');
			
			$.each(brevidy.profileCategories, function (index, value) {
				// iterate through all of the text areas and save it to an object
				profile[value] = $('.profile-content textarea.' + value).val().trim();
			});
			
			$.ajax({
				data: { 'profile':profile },
				type: 'PUT',
				url: profile_path,
				success: function (json) {
					// hide edit button, show save button
					$that.hide();
					$('#cancel-profile').hide();
					$('#edit-profile').show();
					
					// iterate through categories, set the textarea text and show/hide
					$.each(brevidy.profileCategories, function (index, value) {
						// check if the returned string is empty or not
						if (!json.text[value]) {
						  if (value == 'website') {
						    $('.user-info-section p.website').html('');
						  }
						  
							// string is empty
							$('div.' + value).html('<p>None</p>'); 
							// set the textarea contents
							$('.profile-content textarea.' + value).val('None');
						} else {
						  if (value == 'website') {
						    $('.user-info-section p.website').html(json.html[value]);
						    $('.user-info-section p.website p').replaceWith(function() { return $(this).contents(); });
						  }
						  
							// string is not empty
							$('div.' + value).html(json.html[value]); 
							// set the textarea contents
							$('.profile-content textarea.' + value).val(json.text[value]);
						}
						$('.profile-content textarea.' + value).hide();
						$('.profile-content div.' + value).show();
					});

				},
				error: function (response) {
					brevidy.handle_ajax_error("profile", response);
				}
			});
			
			return false;
		});
	
		// if the user cancels, do nothing and set the data back how it was before 
		$('#cancel-profile').click(function () {
			// iterate through categories and show/hide them w/o changes
			$.each(brevidy.profileCategories, function (index, value) {
				$('.profile-content textarea.' + value).hide();
				$('.profile-content div.' + value).show();
			});
			
			$(this).hide();
			$('#save-profile').hide();
			$('#edit-profile').show();
		
			return false;
		});
		
		
// ---------------------------
// VIDEO UPLOAD / SHARE / EDIT
// ---------------------------
    
    // Change selection based on which thumbnail was pressed
		$('.choose-a-thumbnail li').click(function() {	    
				var thumb_number = $(this).attr('data-thumb-number');
	
		    $('li.selected-thumbnail').removeClass('selected-thumbnail');
				$(this).addClass('selected-thumbnail');

				// set new value
				$('input.selected-thumbnail').val(thumb_number);
		});
		
		
// --------------
// ADD TO CHANNEL
// --------------

    // Shows the add to channel area if the user clicked the button for one of their own videos
    $('.show-add-video-meta-area').live('click', function(e) {
      e.preventDefault();
      $('.add-to-channel-warning').remove();
      $('#add-to-channel, .add-video-meta-area').fadeIn('fast'); 
    });
    
    // Handles AJAX error
    $('.add-to-channel-link').live('ajax:error', function(data, xhr, response) {
			brevidy.handle_ajax_error("channel", xhr);
		});
		
		
// -------------------
// EDIT FEATURED VIDEO
// -------------------
    
    // Colors the first 4 featured videos and adds a "FEATURED" tag to them
    brevidy.update_featured_videos = function() {
      // Reset outdated ones
      $('.featured-video-post').css('background-color', '#ededed').children('.featured-video-meta-area').children('span.label.important').hide();
      
      // Highlight the first 4 featured videos
      $.each($('.featured-video-post').slice(0,4), function(index, featured_video) {
        $(this).css('background-color', '#dcf5dc');
        $(this).children('.featured-video-meta-area').children('span.label.important').show();
      });
      
      // Reset the up arrows on all video posts and remove the up arrow from the top one
      $('.featured-video-post').children('.update-position-area').children('.move-to-top').show();
      $('.featured-video-post').eq(0).children('.update-position-area').children('.move-to-top').hide();
    }
    
    // Run this upon page load
    brevidy.update_featured_videos();
    
    // Moves videos upon successful ajax call
    $('a.move-video-to-top').live('ajax:success', function(data, json, response) {
			var idType = 'data-video-id';
			var id = $(this).attr(idType);
			var featured_video = $(this).closest('.featured-video-post');
			var new_featured_video = featured_video.clone();
			var top_featured_video = $('.featured-video-post').eq(0);
			
			// Replace the top featured video object
			featured_video.fadeOut('fast', function () {
			  $(this).remove();
			  top_featured_video.before(new_featured_video).hide().fadeIn('fast');
			  
			  // Update the featured videos highlighting
			  brevidy.update_featured_videos();
			});
			
			// Update the featured video section of the page
			var featured_video_object = $('.featured-video-object['+idType+'='+id+']');
			if (featured_video_object.length) {
			  // It's already showing so just replace it
			  featured_video_object.fadeOut('fast', function() {
			    $(this).remove();
			    $('#featured-videos .featured-video-object').eq(0).before(json.featured_video).hide().fadeIn('fast');
			  });
			} else {
			  // It's not showing on the screen
			  $('#featured-videos .featured-video-object').eq(3).fadeOut('fast', function() {
			    $(this).remove();
			    $('#featured-videos .featured-video-object').eq(0).before(json.featured_video).hide().fadeIn('fast');
			  });
			}
			
		});
		
		// Handles AJAX error
    $('a.move-video-to-top').live('ajax:error', function(data, xhr, response) {
			brevidy.handle_ajax_error("featured video", xhr);
		});
    		

// ----------------
// INVITATIONS PAGE
// ----------------
    
    // Handle ajax errors or success
    $('.send-invites').live('ajax:success', function(data, json, response) {
			brevidy.dialog('Yay!!!', json.message, 'message');
			$('textarea#recipient_email, textarea#personal_message').val('');
		});
    $('.send-invites').live('ajax:error', function(data, xhr, response) {
			brevidy.handle_ajax_error('invitation', xhr);
		});
		
		
// ------------
// ACCOUNT PAGE
// ------------

    // Update text field and check if username available
    var usernameChanged = false;
    var username_field = $('#user_username, #signupUsername');
		$('#user_username, #signupUsername').keyup(function() {
		  $(this).siblings('span').text('http://brevidy.com/' + $(this).val().trim());
		  usernameChanged = true;
		});
		
		// Set up an interval to check for username change
		var checkUsernameInterval = setInterval(function () {
		  if (usernameChanged && username_field.val().trim().length != 0) {
		    usernameChanged = false;
		    username = username_field.val().trim();
		    availability_path = username_field.attr('data-path');
		    
		    // kick off ajax to check username availability
		    $.ajax({
  				data: { 'username':username },
  				type: 'GET',
  				url: availability_path,
  				success: function (json) {
  				  span_sib = username_field.siblings('span');
            span_sib.text('http://brevidy.com/' + username + ' is ' + json.availability_text);
            (json.availability_text == 'available') ? span_sib.removeClass('red').addClass('green') : span_sib.removeClass('green').addClass('red')
  				},
  				error: function (response) {
  					brevidy.dialog('Error', 'There was an error checking the availability of that username.  Please try again later.', 'error');
  				}
  			});
		  } else {
		    if (username_field.val().trim().length == 0) { username_field.siblings('span').removeClass('red green'); }
		  }
		}, 1000);
		
		// Cancel the setInterval if we couldn't find the username field
		if (!username_field.length) { clearInterval(checkUsernameInterval); }
    
    // Handle AJAX requests
    $('#update-user-info input[type=submit], #update-notifications input[type=submit], #update-password input[type=submit]').live('click', function() {
      $(this).siblings('.ajax-animation').fadeIn('fast');
    });
    $('#update-user-info, #update-notifications, #update-password').live('ajax:success', function(data, json, response) {
      $(this).children('.button-area').children('.ajax-animation').hide();
      $(this).children('.button-area').children('.green-checkmark').fadeIn('slow').fadeOut('1000');
      
      $('#old_password, #new_password, #confirm_new_password').val('');
    });
    $('#update-user-info, #update-notifications, #update-password, .unblock-user').live('ajax:error', function(data, xhr, response){
      $(this).children('.button-area').children('.ajax-animation').hide();
      brevidy.handle_ajax_error("user", xhr);
    });
    $('.unblock-user').live('ajax:success', function(data, json, response) {
      $(this).parent().slideUp('fast', function() {
        $(this).remove();
      });
    });
    
    // Handles setting the new background image
    $('.set-new-background-image').live('ajax:success', function(data, json, response) {
      if (json.background_image_id == 0) {
        $('body').removeClass('dark').addClass('light');
      } else if (json.background_image_id == 1) {
        $('body').removeClass('light').addClass('dark');
      }
    });
    // Handles banner image error
    $('.set-new-background-image').live('ajax:error', function(data, xhr, response){
      brevidy.handle_ajax_error("background image", xhr);
    });

    

// ----------------
// EDIT BANNER PAGE
// ----------------

    // Handles setting the new banner image
    $('.set-new-banner-image').live('ajax:success', function(data, json, response) {
      $('.top-banner img').attr('src', json.image_path);
      $.smoothScroll({
        scrollTarget: '#top',
        speed: 1000
      });
    });
    // Handles banner image error
    $('.set-new-banner-image').live('ajax:error', function(data, xhr, response){
      brevidy.handle_ajax_error("banner image", xhr);
    });

  
}); // end of document ready