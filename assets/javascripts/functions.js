/**********************/
/*                  
* Site wide js and jquery functions
*/
/**********************/

// Create a namespace for Brevidy functions and variables
var brevidy = {};

// Set a global AJAX timeout to 90 seconds
$.ajaxSetup({ timeout: 90000 });


/*! 
 * ==========================================================
 * bootstrap-twipsy.js v1.4.0
 * http://twitter.github.com/bootstrap/javascript.html#twipsy
 * Adapted from the original jQuery.tipsy by Jason Frame
 * ==========================================================
 * Copyright 2011 Twitter, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ========================================================== */


!function( $ ) {

  "use strict"

 /* CSS TRANSITION SUPPORT (https://gist.github.com/373874)
  * ======================================================= */

  var transitionEnd

  $(document).ready(function () {

    $.support.transition = (function () {
      var thisBody = document.body || document.documentElement
        , thisStyle = thisBody.style
        , support = thisStyle.transition !== undefined || thisStyle.WebkitTransition !== undefined || thisStyle.MozTransition !== undefined || thisStyle.MsTransition !== undefined || thisStyle.OTransition !== undefined
      return support
    })()

    // set CSS transition event type
    if ( $.support.transition ) {
      transitionEnd = "TransitionEnd"
      if ( $.browser.webkit ) {
      	transitionEnd = "webkitTransitionEnd"
      } else if ( $.browser.mozilla ) {
      	transitionEnd = "transitionend"
      } else if ( $.browser.opera ) {
      	transitionEnd = "oTransitionEnd"
      }
    }

  })


 /* TWIPSY PUBLIC CLASS DEFINITION
  * ============================== */

  var Twipsy = function ( element, options ) {
    this.$element = $(element)
    this.options = options
    this.enabled = true
    this.fixTitle()
  }

  Twipsy.prototype = {

    show: function() {
      var pos
        , actualWidth
        , actualHeight
        , placement
        , $tip
        , tp

      if (this.hasContent() && this.enabled) {
        $tip = this.tip()
        this.setContent()

        if (this.options.animate) {
          $tip.addClass('fade')
        }

        $tip
          .remove()
          .css({ top: 0, left: 0, display: 'block' })
          .prependTo(document.body)

        pos = $.extend({}, this.$element.offset(), {
          width: this.$element[0].offsetWidth
        , height: this.$element[0].offsetHeight
        })

        actualWidth = $tip[0].offsetWidth
        actualHeight = $tip[0].offsetHeight

        placement = maybeCall(this.options.placement, this, [ $tip[0], this.$element[0] ])

        switch (placement) {
          case 'below':
            tp = {top: pos.top + pos.height + this.options.offset, left: pos.left + pos.width / 2 - actualWidth / 2}
            break
          case 'above':
            tp = {top: pos.top - actualHeight - this.options.offset, left: pos.left + pos.width / 2 - actualWidth / 2}
            break
          case 'left':
            tp = {top: pos.top + pos.height / 2 - actualHeight / 2, left: pos.left - actualWidth - this.options.offset}
            break
          case 'right':
            tp = {top: pos.top + pos.height / 2 - actualHeight / 2, left: pos.left + pos.width + this.options.offset}
            break
        }

        $tip
          .css(tp)
          .addClass(placement)
          .addClass('in')
      }
    }

  , setContent: function () {
      var $tip = this.tip()
      $tip.find('.twipsy-inner')[this.options.html ? 'html' : 'text'](this.getTitle())
      $tip[0].className = 'twipsy'
    }

  , hide: function() {
      var that = this
        , $tip = this.tip()

      $tip.removeClass('in')

      function removeElement () {
        $tip.remove()
      }

      $.support.transition && this.$tip.hasClass('fade') ?
        $tip.bind(transitionEnd, removeElement) :
        removeElement()
    }

  , fixTitle: function() {
      var $e = this.$element
      if ($e.attr('title') || typeof($e.attr('data-original-title')) != 'string') {
        $e.attr('data-original-title', $e.attr('title') || '').removeAttr('title')
      }
    }

  , hasContent: function () {
      return this.getTitle()
    }

  , getTitle: function() {
      var title
        , $e = this.$element
        , o = this.options

        this.fixTitle()

        if (typeof o.title == 'string') {
          title = $e.attr(o.title == 'title' ? 'data-original-title' : o.title)
        } else if (typeof o.title == 'function') {
          title = o.title.call($e[0])
        }

        title = ('' + title).replace(/(^\s*|\s*$)/, "")

        return title || o.fallback
    }

  , tip: function() {
      return this.$tip = this.$tip || $('<div class="twipsy" />').html(this.options.template)
    }

  , validate: function() {
      if (!this.$element[0].parentNode) {
        this.hide()
        this.$element = null
        this.options = null
      }
    }

  , enable: function() {
      this.enabled = true
    }

  , disable: function() {
      this.enabled = false
    }

  , toggleEnabled: function() {
      this.enabled = !this.enabled
    }

  , toggle: function () {
      this[this.tip().hasClass('in') ? 'hide' : 'show']()
    }

  }


 /* TWIPSY PRIVATE METHODS
  * ====================== */

   function maybeCall ( thing, ctx, args ) {
     return typeof thing == 'function' ? thing.apply(ctx, args) : thing
   }

 /* TWIPSY PLUGIN DEFINITION
  * ======================== */

  $.fn.twipsy = function (options) {
    $.fn.twipsy.initWith.call(this, options, Twipsy, 'twipsy')
    return this
  }

  $.fn.twipsy.initWith = function (options, Constructor, name) {
    var twipsy
      , binder
      , eventIn
      , eventOut

    if (options === true) {
      return this.data(name)
    } else if (typeof options == 'string') {
      twipsy = this.data(name)
      if (twipsy) {
        twipsy[options]()
      }
      return this
    }

    options = $.extend({}, $.fn[name].defaults, options)

    function get(ele) {
      var twipsy = $.data(ele, name)

      if (!twipsy) {
        twipsy = new Constructor(ele, $.fn.twipsy.elementOptions(ele, options))
        $.data(ele, name, twipsy)
      }

      return twipsy
    }

    function enter() {
      var twipsy = get(this)
      twipsy.hoverState = 'in'

      if (options.delayIn == 0) {
        twipsy.show()
      } else {
        twipsy.fixTitle()
        setTimeout(function() {
          if (twipsy.hoverState == 'in') {
            twipsy.show()
          }
        }, options.delayIn)
      }
    }

    function leave() {
      var twipsy = get(this)
      twipsy.hoverState = 'out'
      if (options.delayOut == 0) {
        twipsy.hide()
      } else {
        setTimeout(function() {
          if (twipsy.hoverState == 'out') {
            twipsy.hide()
          }
        }, options.delayOut)
      }
    }

    if (!options.live) {
      this.each(function() {
        get(this)
      })
    }

    if (options.trigger != 'manual') {
      binder   = options.live ? 'live' : 'bind'
      eventIn  = options.trigger == 'hover' ? 'mouseenter' : 'focus'
      eventOut = options.trigger == 'hover' ? 'mouseleave' : 'blur'
      this[binder](eventIn, enter)[binder](eventOut, leave)
    }

    return this
  }

  $.fn.twipsy.Twipsy = Twipsy

  $.fn.twipsy.defaults = {
    animate: true
  , delayIn: 0
  , delayOut: 0
  , fallback: ''
  , placement: 'above'
  , html: false
  , live: true
  , offset: 0
  , title: 'title'
  , trigger: 'hover'
  , template: '<div class="twipsy-arrow"></div><div class="twipsy-inner"></div>'
  }

  $.fn.twipsy.rejectAttrOptions = [ 'title' ]

  $.fn.twipsy.elementOptions = function(ele, options) {
    var data = $(ele).data()
      , rejects = $.fn.twipsy.rejectAttrOptions
      , i = rejects.length

    while (i--) {
      delete data[rejects[i]]
    }

    return $.extend({}, options, data)
  }

}( window.jQuery || window.ender ); // end twitter twipsy


/*! 
 * =========================================================
 * bootstrap-modal.js v1.4.0
 * http://twitter.github.com/bootstrap/javascript.html#modal
 * =========================================================
 * Copyright 2011 Twitter, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ========================================================= */


!function( $ ){

  "use strict"

 /* CSS TRANSITION SUPPORT (https://gist.github.com/373874)
  * ======================================================= */

  var transitionEnd

  $(document).ready(function () {

    $.support.transition = (function () {
      var thisBody = document.body || document.documentElement
        , thisStyle = thisBody.style
        , support = thisStyle.transition !== undefined || thisStyle.WebkitTransition !== undefined || thisStyle.MozTransition !== undefined || thisStyle.MsTransition !== undefined || thisStyle.OTransition !== undefined
      return support
    })()

    // set CSS transition event type
    if ( $.support.transition ) {
      transitionEnd = "TransitionEnd"
      if ( $.browser.webkit ) {
      	transitionEnd = "webkitTransitionEnd"
      } else if ( $.browser.mozilla ) {
      	transitionEnd = "transitionend"
      } else if ( $.browser.opera ) {
      	transitionEnd = "oTransitionEnd"
      }
    }

  })


 /* MODAL PUBLIC CLASS DEFINITION
  * ============================= */

  var Modal = function ( content, options ) {
    this.settings = $.extend({}, $.fn.modal.defaults, options)
    this.$element = $(content)
      .delegate('.close', 'click.modal', $.proxy(this.hide, this))

    if ( this.settings.show ) {
      this.show()
    }

    return this
  }

  Modal.prototype = {

      toggle: function () {
        return this[!this.isShown ? 'show' : 'hide']()
      }

    , show: function () {
        var that = this
        this.isShown = true
        this.$element.trigger('show')

        escape.call(this)
        backdrop.call(this, function () {
          var transition = $.support.transition && that.$element.hasClass('fade')

          that.$element
            .appendTo(document.body)
            .show()

          if (transition) {
            that.$element[0].offsetWidth // force reflow
          }

          that.$element.addClass('in')

          transition ?
            that.$element.one(transitionEnd, function () { that.$element.trigger('shown') }) :
            that.$element.trigger('shown')

        })

        return this
      }

    , hide: function (e) {
        e && e.preventDefault()

        if ( !this.isShown ) {
          return this
        }

        var that = this
        this.isShown = false

        escape.call(this)

        this.$element
          .trigger('hide')
          .removeClass('in')

        $.support.transition && this.$element.hasClass('fade') ?
          hideWithTransition.call(this) :
          hideModal.call(this)

        return this
      }

  }


 /* MODAL PRIVATE METHODS
  * ===================== */

  function hideWithTransition() {
    // firefox drops transitionEnd events :{o
    var that = this
      , timeout = setTimeout(function () {
          that.$element.unbind(transitionEnd)
          hideModal.call(that)
        }, 500)

    this.$element.one(transitionEnd, function () {
      clearTimeout(timeout)
      hideModal.call(that)
    })
  }

  function hideModal (that) {
    this.$element
      .hide()
      .trigger('hidden')

    backdrop.call(this)
  }

  function backdrop ( callback ) {
    var that = this
      , animate = this.$element.hasClass('fade') ? 'fade' : ''
    if ( this.isShown && this.settings.backdrop ) {
      var doAnimate = $.support.transition && animate

      this.$backdrop = $('<div class="modal-backdrop ' + animate + '" />')
        .appendTo(document.body)

      if ( this.settings.backdrop != 'static' ) {
        this.$backdrop.click($.proxy(this.hide, this))
      }

      if ( doAnimate ) {
        this.$backdrop[0].offsetWidth // force reflow
      }

      this.$backdrop.addClass('in')

      doAnimate ?
        this.$backdrop.one(transitionEnd, callback) :
        callback()

    } else if ( !this.isShown && this.$backdrop ) {
      this.$backdrop.removeClass('in')

      $.support.transition && this.$element.hasClass('fade')?
        this.$backdrop.one(transitionEnd, $.proxy(removeBackdrop, this)) :
        removeBackdrop.call(this)

    } else if ( callback ) {
       callback()
    }
  }

  function removeBackdrop() {
    this.$backdrop.remove()
    this.$backdrop = null
  }

  function escape() {
    var that = this
    if ( this.isShown && this.settings.keyboard ) {
      $(document).bind('keyup.modal', function ( e ) {
        if ( e.which == 27 ) {
          that.hide()
        }
      })
    } else if ( !this.isShown ) {
      $(document).unbind('keyup.modal')
    }
  }


 /* MODAL PLUGIN DEFINITION
  * ======================= */

  $.fn.modal = function ( options ) {
    var modal = this.data('modal')

    if (!modal) {

      if (typeof options == 'string') {
        options = {
          show: /show|toggle/.test(options)
        }
      }

      return this.each(function () {
        $(this).data('modal', new Modal(this, options))
      })
    }

    if ( options === true ) {
      return modal
    }

    if ( typeof options == 'string' ) {
      modal[options]()
    } else if ( modal ) {
      modal.toggle()
    }

    return this
  }

  $.fn.modal.Modal = Modal

  $.fn.modal.defaults = {
    backdrop: false
  , keyboard: false
  , show: false
  }


 /* MODAL DATA- IMPLEMENTATION
  * ========================== */

  $(document).ready(function () {
    $('body').delegate('[data-controls-modal]', 'click', function (e) {
      e.preventDefault()
      var $this = $(this).data('show', true)
      $('#' + $this.attr('data-controls-modal')).modal( $this.data() )
    })
  })

}( window.jQuery || window.ender ); // end twitter modals


/*! 
 * ========================================================
 * bootstrap-tabs.js v1.4.0
 * http://twitter.github.com/bootstrap/javascript.html#tabs
 * ========================================================
 * Copyright 2011 Twitter, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ======================================================== */


!function( $ ){

  "use strict"

  function activate ( element, container ) {

    //
    // CUSTOM FOR BREVIDY
    //
    // Show / Hide plupload flash uploader
    
    var allowed_to_change_tabs = false;
    var progress_bar = $('#progress-bar');
    
    // Check if we should let them change tabs or not based on
    // whether or not we're uploading a file
    if (element.attr('id') == 'upload-image') {
      allowed_to_change_tabs = true;
    } else {
      if (progress_bar.is(':visible')) {
        if ((progress_bar).children('.progress').hasClass('error')) { allowed_to_change_tabs = true; }
      } else {
       allowed_to_change_tabs = true;
      }
    }
    
    if (allowed_to_change_tabs) {    
      // Show / Hide uploader button
      if (element.attr('id') == 'upload-image') { $('.plupload').css('display', 'block'); } else { $('.plupload').css('display', 'none'); }
      
      container
        .find('> .active')
        .removeClass('active')
        .find('> .dropdown-menu > .active')
        .removeClass('active')

      element.addClass('active')

      if ( element.parent('.dropdown-menu') ) {
        element.closest('li.dropdown').addClass('active')
      }
    }
    
  }

  function tab( e ) {
    var $this = $(this)
      , $ul = $this.closest('ul:not(.dropdown-menu)')
      , href = $this.attr('href')
      , previous
      , $href

    if ( /^#\w+/.test(href) ) {
      e.preventDefault()

      if ( $this.parent('li').hasClass('active') ) {
        return
      }

      previous = $ul.find('.active a').last()[0]
      $href = $(href)

      activate($this.parent('li'), $ul)
      activate($href, $href.parent())

      $this.trigger({
        type: 'change'
      , relatedTarget: previous
      })
    }
  }


 /* TABS/PILLS PLUGIN DEFINITION
  * ============================ */

  $.fn.tabs = $.fn.pills = function ( selector ) {
    return this.each(function () {
      $(this).delegate(selector || '.tabs li > a, .pills > li > a', 'click', tab)
    })
  }

  $(document).ready(function () {
    $('body').tabs('ul[data-tabs] li > a, ul[data-pills] > li > a')
  })

}( window.jQuery || window.ender ); // end twitter tabs


/*!
 * ===========================================================
 * bootstrap-popover.js v1.4.0
 * http://twitter.github.com/bootstrap/javascript.html#popover
 * ===========================================================
 * Copyright 2011 Twitter, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * =========================================================== */


!function( $ ) {

 "use strict"

  var Popover = function ( element, options ) {
    this.$element = $(element)
    this.options = options
    this.enabled = true
    this.fixTitle()
  }

  /* NOTE: POPOVER EXTENDS BOOTSTRAP-TWIPSY.js
     ========================================= */

  Popover.prototype = $.extend({}, $.fn.twipsy.Twipsy.prototype, {

    setContent: function () {
      var $tip = this.tip()
      $tip.find('.title')[this.options.html ? 'html' : 'text'](this.getTitle())
      $tip.find('.content p')[this.options.html ? 'html' : 'text'](this.getContent())
      $tip[0].className = 'popover'
    }

  , hasContent: function () {
      return this.getTitle() || this.getContent()
    }

  , getContent: function () {
      var content
       , $e = this.$element
       , o = this.options

      if (typeof this.options.content == 'string') {
        content = $e.attr(this.options.content)
      } else if (typeof this.options.content == 'function') {
        content = this.options.content.call(this.$element[0])
      }

      return content
    }

  , tip: function() {
      if (!this.$tip) {
        this.$tip = $('<div class="popover" />')
          .html(this.options.template)
      }
      return this.$tip
    }

  })


 /* POPOVER PLUGIN DEFINITION
  * ======================= */

  $.fn.popover = function (options) {
    if (typeof options == 'object') options = $.extend({}, $.fn.popover.defaults, options)
    $.fn.twipsy.initWith.call(this, options, Popover, 'popover')
    return this
  }

  $.fn.popover.defaults = $.extend({} , $.fn.twipsy.defaults, {
    placement: 'right'
  , content: 'data-content'
  , template: '<div class="arrow"></div><div class="inner"><h5 class="title"></h5><div class="content"><p></p></div></div>'
  })

  $.fn.twipsy.rejectAttrOptions.push( 'content' )

}( window.jQuery || window.ender ); // end twitter popovers


/*!
 * Unobtrusive scripting adapter for jQuery
 *
 * Requires jQuery 1.4.4 or later.
 * https://github.com/rails/jquery-ujs

 * Uploading file using rails.js
 * =============================
 *
 * By default, browsers do not allow files to be uploaded via AJAX. As a result, if there are any non-blank file fields
 * in the remote form, this adapter aborts the AJAX submission and allows the form to submit through standard means.
 *
 * The `ajax:aborted:file` event allows you to bind your own handler to process the form submission however you wish.
 *
 * Ex:
 *     $('form').live('ajax:aborted:file', function(event, elements){
 *       // Implement own remote file-transfer handler here for non-blank file inputs passed in `elements`.
 *       // Returning false in this handler tells rails.js to disallow standard form submission
 *       return false;
 *     });
 *
 * The `ajax:aborted:file` event is fired when a file-type input is detected with a non-blank value.
 *
 * Third-party tools can use this hook to detect when an AJAX file upload is attempted, and then use
 * techniques like the iframe method to upload the file instead.
 *
 * Required fields in rails.js
 * ===========================
 *
 * If any blank required inputs (required="required") are detected in the remote form, the whole form submission
 * is canceled. Note that this is unlike file inputs, which still allow standard (non-AJAX) form submission.
 *
 * The `ajax:aborted:required` event allows you to bind your own handler to inform the user of blank required inputs.
 *
 * !! Note that Opera does not fire the form's submit event if there are blank required inputs, so this event may never
 *    get fired in Opera. This event is what causes other browsers to exhibit the same submit-aborting behavior.
 *
 * Ex:
 *     $('form').live('ajax:aborted:required', function(event, elements){
 *       // Returning false in this handler tells rails.js to submit the form anyway.
 *       // The blank required inputs are passed to this function in `elements`.
 *       return ! confirm("Would you like to submit the form with missing info?");
 *     });
 */

(function($, undefined) {
  // Shorthand to make it a little easier to call public rails functions from within rails.js
  var rails;

  $.rails = rails = {
    // Link elements bound by jquery-ujs
    linkClickSelector: 'a[data-confirm], a[data-method], a[data-remote]',

		// Select elements bound by jquery-ujs
		selectChangeSelector: 'select[data-remote]',

    // Form elements bound by jquery-ujs
    formSubmitSelector: 'form',

    // Form input elements bound by jquery-ujs
    formInputClickSelector: 'form input[type=submit], form input[type=image], form button[type=submit], form button:not([type])',

    // Form input elements disabled during form submission
    disableSelector: 'input[data-disable-with], button[data-disable-with], textarea[data-disable-with]',

    // Form input elements re-enabled after form submission
    enableSelector: 'input[data-disable-with]:disabled, button[data-disable-with]:disabled, textarea[data-disable-with]:disabled',

    // Form required input elements
    requiredInputSelector: 'input[name][required]:not([disabled]),textarea[name][required]:not([disabled])',

    // Form file input elements
    fileInputSelector: 'input:file',

    // Make sure that every Ajax request sends the CSRF token
    CSRFProtection: function(xhr) {
      var token = $('meta[name="csrf-token"]').attr('content');
      if (token) xhr.setRequestHeader('X-CSRF-Token', token);
    },

    // Triggers an event on an element and returns false if the event result is false
    fire: function(obj, name, data) {
      var event = $.Event(name);
      obj.trigger(event, data);
      return event.result !== false;
    },

    // Default confirm dialog, may be overridden with custom confirm dialog in $.rails.confirm
    confirm: function(message) {
      return confirm(message);
    },

    // Default ajax function, may be overridden with custom function in $.rails.ajax
    ajax: function(options) {
      return $.ajax(options);
    },

    // Submits "remote" forms and links with ajax
    handleRemote: function(element) {
      var method, url, data,
        crossDomain = element.data('cross-domain') || null,
        dataType = element.data('type') || ($.ajaxSettings && $.ajaxSettings.dataType);

      if (rails.fire(element, 'ajax:before')) {

        if (element.is('form')) {
          method = element.attr('method');
          url = element.attr('action');
          data = element.serializeArray();
          // memoized value from clicked submit button
          var button = element.data('ujs:submit-button');
          if (button) {
            data.push(button);
            element.data('ujs:submit-button', null);
          }
        } else if (element.is('select')) {
          method = element.data('method');
          url = element.data('url');
					data = element.serialize();
					if (element.data('params')) data = data + "&" + element.data('params'); 
        } else {
           method = element.data('method');
           url = element.attr('href');
           data = element.data('params') || null; 
        }

        options = {
          type: method || 'GET', data: data, dataType: dataType, crossDomain: crossDomain,
          // stopping the "ajax:beforeSend" event will cancel the ajax request
          beforeSend: function(xhr, settings) {
            if (settings.dataType === undefined) {
              xhr.setRequestHeader('accept', '*/*;q=0.5, ' + settings.accepts.script);
            }
            return rails.fire(element, 'ajax:beforeSend', [xhr, settings]);
          },
          success: function(data, status, xhr) {
            element.trigger('ajax:success', [data, status, xhr]);
          },
          complete: function(xhr, status) {
            element.trigger('ajax:complete', [xhr, status]);
          },
          error: function(xhr, status, error) {
            element.trigger('ajax:error', [xhr, status, error]);
          }
        };
        // Do not pass url to `ajax` options if blank
        if (url) { $.extend(options, { url: url }); }

        rails.ajax(options);
      }
    },

    // Handles "data-method" on links such as:
    // <a href="/users/5" data-method="delete" rel="nofollow" data-confirm="Are you sure?">Delete</a>
    handleMethod: function(link) {
      var href = link.attr('href'),
        method = link.data('method'),
        csrf_token = $('meta[name=csrf-token]').attr('content'),
        csrf_param = $('meta[name=csrf-param]').attr('content'),
        form = $('<form method="post" action="' + href + '"></form>'),
        metadata_input = '<input name="_method" value="' + method + '" type="hidden" />';

      if (csrf_param !== undefined && csrf_token !== undefined) {
        metadata_input += '<input name="' + csrf_param + '" value="' + csrf_token + '" type="hidden" />';
      }

      form.hide().append(metadata_input).appendTo('body');
      form.submit();
    },

    /* Disables form elements:
      - Caches element value in 'ujs:enable-with' data store
      - Replaces element text with value of 'data-disable-with' attribute
      - Adds disabled=disabled attribute
    */
    disableFormElements: function(form) {
      form.find(rails.disableSelector).each(function() {
        var element = $(this), method = element.is('button') ? 'html' : 'val';
        element.data('ujs:enable-with', element[method]());
        element[method](element.data('disable-with'));
        element.attr('disabled', 'disabled');
      });
    },

    /* Re-enables disabled form elements:
      - Replaces element text with cached value from 'ujs:enable-with' data store (created in `disableFormElements`)
      - Removes disabled attribute
    */
    enableFormElements: function(form) {
      form.find(rails.enableSelector).each(function() {
        var element = $(this), method = element.is('button') ? 'html' : 'val';
        if (element.data('ujs:enable-with')) element[method](element.data('ujs:enable-with'));
        element.removeAttr('disabled');
      });
    },

   /* For 'data-confirm' attribute:
      - Fires `confirm` event
      - Shows the confirmation dialog
      - Fires the `confirm:complete` event

      Returns `true` if no function stops the chain and user chose yes; `false` otherwise.
      Attaching a handler to the element's `confirm` event that returns a `falsy` value cancels the confirmation dialog.
      Attaching a handler to the element's `confirm:complete` event that returns a `falsy` value makes this function
      return false. The `confirm:complete` event is fired whether or not the user answered true or false to the dialog.
   */
    allowAction: function(element) {
      var message = element.data('confirm'),
          answer = false, callback;
      if (!message) { return true; }

      if (rails.fire(element, 'confirm')) {
        answer = rails.confirm(message);
        callback = rails.fire(element, 'confirm:complete', [answer]);
      }
      return answer && callback;
    },

    // Helper function which checks for blank inputs in a form that match the specified CSS selector
    blankInputs: function(form, specifiedSelector, nonBlank) {
      var inputs = $(), input,
        selector = specifiedSelector || 'input,textarea';
      form.find(selector).each(function() {
        input = $(this);
        // Collect non-blank inputs if nonBlank option is true, otherwise, collect blank inputs
        if (nonBlank ? input.val() : !input.val()) {
          inputs = inputs.add(input);
        }
      });
      return inputs.length ? inputs : false;
    },

    // Helper function which checks for non-blank inputs in a form that match the specified CSS selector
    nonBlankInputs: function(form, specifiedSelector) {
      return rails.blankInputs(form, specifiedSelector, true); // true specifies nonBlank
    },

    // Helper function, needed to provide consistent behavior in IE
    stopEverything: function(e) {
      $(e.target).trigger('ujs:everythingStopped');
      e.stopImmediatePropagation();
      return false;
    },

    // find all the submit events directly bound to the form and
    // manually invoke them. If anyone returns false then stop the loop
    callFormSubmitBindings: function(form) {
      var events = form.data('events'), continuePropagation = true;
      if (events !== undefined && events['submit'] !== undefined) {
        $.each(events['submit'], function(i, obj){
          if (typeof obj.handler === 'function') return continuePropagation = obj.handler(obj.data);
        });
      }
      return continuePropagation;
    }
  };

  // ajaxPrefilter is a jQuery 1.5 feature
  if ('ajaxPrefilter' in $) {
    $.ajaxPrefilter(function(options, originalOptions, xhr){ if ( !options.crossDomain ) { rails.CSRFProtection(xhr); }});
  } else {
    $(document).ajaxSend(function(e, xhr, options){ if ( !options.crossDomain ) { rails.CSRFProtection(xhr); }});
  }

  $(rails.linkClickSelector).live('click.rails', function(e) {
    var link = $(this);
    if (!rails.allowAction(link)) return rails.stopEverything(e);

    if (link.data('remote') !== undefined) {
      rails.handleRemote(link);
      return false;
    } else if (link.data('method')) {
      rails.handleMethod(link);
      return false;
    }
  });

	$(rails.selectChangeSelector).live('change.rails', function(e) {
    var link = $(this);
    if (!rails.allowAction(link)) return rails.stopEverything(e);

    rails.handleRemote(link);
    return false;
  });	

  $(rails.formSubmitSelector).live('submit.rails', function(e) {
    var form = $(this),
      remote = form.data('remote') !== undefined,
      blankRequiredInputs = rails.blankInputs(form, rails.requiredInputSelector),
      nonBlankFileInputs = rails.nonBlankInputs(form, rails.fileInputSelector);

    if (!rails.allowAction(form)) return rails.stopEverything(e);

    // skip other logic when required values are missing or file upload is present
    if (blankRequiredInputs && rails.fire(form, 'ajax:aborted:required', [blankRequiredInputs])) {
      return rails.stopEverything(e);
    }

    if (remote) {
      if (nonBlankFileInputs) {
        return rails.fire(form, 'ajax:aborted:file', [nonBlankFileInputs]);
      }

      // If browser does not support submit bubbling, then this live-binding will be called before direct
      // bindings. Therefore, we should directly call any direct bindings before remotely submitting form.
      if (!$.support.submitBubbles && rails.callFormSubmitBindings(form) === false) return rails.stopEverything(e);

      rails.handleRemote(form);
      return false;
    } else {
      // slight timeout so that the submit button gets properly serialized
      setTimeout(function(){ rails.disableFormElements(form); }, 13);
    }
  });

  $(rails.formInputClickSelector).live('click.rails', function(event) {
    var button = $(this);

    if (!rails.allowAction(button)) return rails.stopEverything(event);

    // register the pressed submit button
    var name = button.attr('name'),
      data = name ? {name:name, value:button.val()} : null;

    button.closest('form').data('ujs:submit-button', data);
  });

  $(rails.formSubmitSelector).live('ajax:beforeSend.rails', function(event) {
    if (this == event.target) rails.disableFormElements($(this));
  });

  $(rails.formSubmitSelector).live('ajax:complete.rails', function(event) {
    if (this == event.target) rails.enableFormElements($(this));
  });

})( jQuery );


// Check maximum character limit on forms
// (c) 2010 matthew button
// released on http://that-matt.com/2010/04/updated-textarea-maxlength-with-jquery-plugin/

$.fn.limitMaxlength = function(options){

	var settings = jQuery.extend({
    	attribute: "maxlength",
    	onLimit: function(){},
    	onEdit: function(){}
  	}, options);

  // Event handler to limit the textarea
  	var onEdit = function() {
    	var textarea = jQuery(this);
    	var maxlength = parseInt(textarea.attr(settings.attribute));

    	if(textarea.val().length > maxlength) {
      		textarea.val(textarea.val().substr(0, maxlength));
      		// Call the onlimit handler within the scope of the textarea
      		jQuery.proxy(settings.onLimit, this)();
    	}

    	// Call the onEdit handler within the scope of the textarea
    	jQuery.proxy(settings.onEdit, this)(maxlength - textarea.val().length);
  	}

  	this.each(onEdit);

  	return this.keyup(onEdit)
    	.keydown(onEdit)
    	.focus(onEdit);
};

// Check maximum character lengths for input fields
var onEditCallback = function(remaining) {
	var pluralizedTextLimit = (remaining == 1) ? " character left" : " characters left";
	$(this).siblings('.chars-remaining').text(remaining + pluralizedTextLimit);
};


/*!
 * jQuery Smooth Scroll Plugin v1.4.1
 *
 * Date: Tue Nov 15 14:24:14 2011 EST
 * Requires: jQuery v1.3+
 *
 * Copyright 2010, Karl Swedberg
 * Dual licensed under the MIT and GPL licenses (just like jQuery):
 * http://www.opensource.org/licenses/mit-license.php
 * http://www.gnu.org/licenses/gpl.html
 *
 *
 *
 *
*/
(function(b){function l(c){return c.replace(/^\//,"").replace(/(index|default).[a-zA-Z]{3,4}$/,"").replace(/\/$/,"")}function m(c){return c.replace(/(:|\.)/g,"\\$1")}var n=l(location.pathname),o=function(c){var e=[],a=false,d=c.dir&&c.dir=="left"?"scrollLeft":"scrollTop";this.each(function(){if(!(this==document||this==window)){var g=b(this);if(g[d]()>0)e.push(this);else{g[d](1);a=g[d]()>0;g[d](0);a&&e.push(this)}}});if(c.el==="first"&&e.length)e=[e.shift()];return e};b.fn.extend({scrollable:function(c){return this.pushStack(o.call(this,
{dir:c}))},firstScrollable:function(c){return this.pushStack(o.call(this,{el:"first",dir:c}))},smoothScroll:function(c){c=c||{};var e=b.extend({},b.fn.smoothScroll.defaults,c);this.die("click.smoothscroll").live("click.smoothscroll",function(a){var d={},g=b(this),h=location.hostname===this.hostname||!this.hostname,f=e.scrollTarget||(l(this.pathname)||n)===n,j=m(this.hash),i=true;if(!e.scrollTarget&&(!h||!f||!j))i=false;else{h=e.exclude;f=0;for(var k=h.length;i&&f<k;)if(g.is(m(h[f++])))i=false;h=e.excludeWithin;
f=0;for(k=h.length;i&&f<k;)if(g.closest(h[f++]).length)i=false}if(i){a.preventDefault();b.extend(d,e,{scrollTarget:e.scrollTarget||j,link:this});b.smoothScroll(d)}});return this}});b.smoothScroll=function(c,e){var a,d,g,h=0;d="offset";var f="scrollTop",j={};if(typeof c==="number"){a=b.fn.smoothScroll.defaults;g=c}else{a=b.extend({},b.fn.smoothScroll.defaults,c||{});if(a.scrollElement){d="position";a.scrollElement.css("position")=="static"&&a.scrollElement.css("position","relative")}g=e||b(a.scrollTarget)[d]()&&
b(a.scrollTarget)[d]()[a.direction]||0}a=b.extend({link:null},a);f=a.direction=="left"?"scrollLeft":f;if(a.scrollElement){d=a.scrollElement;h=d[f]()}else d=b("html, body").firstScrollable();j[f]=g+h+a.offset;b.isFunction(a.beforeScroll)&&a.beforeScroll.call(d,a);d.animate(j,{duration:a.speed,easing:a.easing,complete:function(){a.afterScroll&&b.isFunction(a.afterScroll)&&a.afterScroll.call(a.link,a)}})};b.smoothScroll.version="1.4.1";b.fn.smoothScroll.defaults={exclude:[],excludeWithin:[],offset:0,
direction:"top",scrollElement:null,scrollTarget:null,beforeScroll:null,afterScroll:null,easing:"swing",speed:400}})(jQuery);


/*!
 * jQuery Expander Plugin v1.3.1
 *
 * Date: Tue Dec 06 00:02:41 2011 EST
 * Requires: jQuery v1.3+
 *
 * Copyright 2011, Karl Swedberg
 * Dual licensed under the MIT and GPL licenses (just like jQuery):
 * http://www.opensource.org/licenses/mit-license.php
 * http://www.gnu.org/licenses/gpl.html
 *
*/
(function(d){d.expander={version:"1.3.1",defaults:{slicePoint:100,preserveWords:true,widow:4,expandText:"read more",expandPrefix:"&hellip; ",expandAfterSummary:false,summaryClass:"summary",detailClass:"details",moreClass:"read-more",lessClass:"read-less",collapseTimer:0,expandEffect:"fadeIn",expandSpeed:250,collapseEffect:"fadeOut",collapseSpeed:200,userCollapse:true,userCollapseText:"read less",userCollapsePrefix:" ",onSlice:null,beforeExpand:null,afterExpand:null,onCollapse:null}};d.fn.expander=
function(F){function G(a,c){var h="span",g=a.summary;if(c){h="div";if(t.test(g)&&!a.expandAfterSummary)g=g.replace(t,a.moreLabel+"$1");else g+=a.moreLabel;g='<div class="'+a.summaryClass+'">'+g+"</div>"}else g+=a.moreLabel;return[g,"<",h+' class="'+a.detailClass+'"',">",a.details,"</"+h+">"].join("")}function H(a){var c='<span class="'+a.moreClass+'">'+a.expandPrefix;c+='<a href="#">'+a.expandText+"</a></span>";return c}function u(a,c){if(a.lastIndexOf("<")>a.lastIndexOf(">"))a=a.slice(0,a.lastIndexOf("<"));
if(c)a=a.replace(I,"");return a}function v(a,c){c.stop(true,true)[a.collapseEffect](a.collapseSpeed,function(){c.prev("span."+a.moreClass).show().length||c.parent().children("div."+a.summaryClass).show().find("span."+a.moreClass).show()})}function J(a,c,h){if(a.collapseTimer)w=setTimeout(function(){v(a,c);d.isFunction(a.onCollapse)&&a.onCollapse.call(h,false)},a.collapseTimer)}var x=d.extend({},d.expander.defaults,F),K=/^<(?:area|br|col|embed|hr|img|input|link|meta|param).*>$/i,I=/(&(?:[^;]+;)?|\w+)$/,
L=/<\/?(\w+)[^>]*>/g,y=/<(\w+)[^>]*>/g,z=/<\/(\w+)>/g,t=/(<\/[^>]+>)\s*$/,M=/^<[^>]+>.?/,w;this.each(function(){var a,c,h,g,k,m,s,A=[],q=[],n={},o=this,f=d(this),B=d([]),b=d.meta?d.extend({},x,f.data()):x,N=!!f.find("."+b.detailClass).length,p=!!f.find("*").filter(function(){return/^block|table|list/.test(d(this).css("display"))}).length,r=(p?"div":"span")+"."+b.detailClass,C="span."+b.moreClass,O=b.expandSpeed||0,l=d.trim(f.html());d.trim(f.text());var e=l.slice(0,b.slicePoint);if(!d.data(this,"expander")){d.data(this,
"expander",true);d.each(["onSlice","beforeExpand","afterExpand","onCollapse"],function(i,j){n[j]=d.isFunction(b[j])});e=u(e);for(summTagless=e.replace(L,"").length;summTagless<b.slicePoint;){newChar=l.charAt(e.length);if(newChar=="<")newChar=l.slice(e.length).match(M)[0];e+=newChar;summTagless++}e=u(e,b.preserveWords);g=e.match(y)||[];k=e.match(z)||[];h=[];d.each(g,function(i,j){K.test(j)||h.push(j)});g=h;c=k.length;for(a=0;a<c;a++)k[a]=k[a].replace(z,"$1");d.each(g,function(i,j){var D=j.replace(y,
"$1"),E=d.inArray(D,k);if(E===-1){A.push(j);q.push("</"+D+">")}else k.splice(E,1)});q.reverse();if(N){c=f.find(r).remove().html();e=f.html();l=e+c;a=""}else{c=l.slice(e.length);if(c===""||c.split(/\s+/).length<b.widow)return;a=q.pop()||"";e+=q.join("");c=A.join("")+c}b.moreLabel=f.find(C).length?"":H(b);if(p)c=l;e+=a;b.summary=e;b.details=c;b.lastCloseTag=a;if(n.onSlice)b=(h=b.onSlice.call(o,b))&&h.details?h:b;p=G(b,p);f.html(p);m=f.find(r);s=f.find(C);m.hide();s.find("a").unbind("click.expander").bind("click.expander",
function(i){i.preventDefault();s.hide();B.hide();n.beforeExpand&&b.beforeExpand.call(o);m.stop(false,true)[b.expandEffect](O,function(){m.css({zoom:""});n.afterExpand&&b.afterExpand.call(o);J(b,m,o)})});B=f.find("div."+b.summaryClass);b.userCollapse&&!f.find("span."+b.lessClass).length&&f.find(r).append('<span class="'+b.lessClass+'">'+b.userCollapsePrefix+'<a href="#">'+b.userCollapseText+"</a></span>");f.find("span."+b.lessClass+" a").unbind("click.expander").bind("click.expander",function(i){i.preventDefault();
clearTimeout(w);i=d(this).closest(r);v(b,i);n.onCollapse&&b.onCollapse.call(o,true)})}});return this};d.fn.expander.defaults=d.expander.defaults})(jQuery);
  

/*!
--------------------------------
Infinite Scroll
--------------------------------
+ https://github.com/paulirish/infinite-scroll
+ version 2.0b2.111027
+ Copyright 2011 Paul Irish & Luke Shumard
+ Licensed under the MIT license
+ Documentation: http://infinite-scroll.com/
*/

(function (window, $, undefined) {

    $.infinitescroll = function infscr(options, callback, element) {

        this.element = $(element);
        this._create(options, callback);

    };

    $.infinitescroll.defaults = {
        loading: {
            finished: undefined,
            finishedMsg: "",
            img: "http://www.infinite-scroll.com/loading.gif",
            msg: null,
            msgText: "LOADING MORE...",
            selector: null,
            speed: 'fast',
            start: undefined
        },
        state: {
            isDuringAjax: false,
            isInvalidPage: false,
            isDestroyed: false,
            isDone: false,
            // For when it goes all the way through the archive.
            isPaused: false,
            currPage: 1
        },
        callback: undefined,
        debug: false,
        behavior: undefined,
        binder: $(window),
        // used to cache the selector
        nextSelector: "div.navigation a:first",
        navSelector: "div.navigation",
        contentSelector: null,
        // rename to pageFragment
        extraScrollPx: 150,
        itemSelector: "div.post",
        animate: false,
        pathParse: undefined,
        dataType: 'html',
        appendCallback: true,
        bufferPx: 40,
        errorCallback: function () {},
        infid: 0,
        //Instance ID
        pixelsFromNavToBottom: undefined,
        path: undefined,
        pathOptions: undefined
    };


    $.infinitescroll.prototype = {

/*	
        ----------------------------
        Private methods
        ----------------------------
        */

        // Bind or unbind from scroll
        _binding: function infscr_binding(binding) {

            var instance = this,
                opts = instance.options;

            opts.v = '2.0b2.111027';

            // if behavior is defined and this function is extended, call that instead of default
            if ( !! opts.behavior && this['_binding_' + opts.behavior] !== undefined) {
                this['_binding_' + opts.behavior].call(this);
                return;
            }

            if (binding !== 'bind' && binding !== 'unbind') {
                this._debug('Binding value  ' + binding + ' not valid')
                return false;
            }

            if (binding == 'unbind') {

                (this.options.binder).unbind('smartscroll.infscr.' + instance.options.infid);

            } else {

                (this.options.binder)[binding]('smartscroll.infscr.' + instance.options.infid, function () {
                    instance.scroll();
                });

            };

            this._debug('Binding', binding);

        },

        // Fundamental aspects of the plugin are initialized
        _create: function infscr_create(options, callback) {

            // If selectors from options aren't valid, return false
            if (!this._validate(options)) {
                return false;
            }
            // Define options and shorthand
            var opts = this.options = $.extend(true, {}, $.infinitescroll.defaults, options),
                // get the relative URL - everything past the domain name.
                relurl = /(.*?\/\/).*?(\/.*)/,
                path = $(opts.nextSelector).attr('href');

            // contentSelector is 'page fragment' option for .load() / .ajax() calls
            opts.contentSelector = opts.contentSelector || this.element;

            // loading.selector - if we want to place the load message in a specific selector, defaulted to the contentSelector
            opts.loading.selector = opts.loading.selector || opts.contentSelector;

            // if there's not path, return
            if (!path) {
                this._debug('Navigation selector not found');
                return;
            }

            // Set the path to be a relative URL from root.
            opts.path = this._determinepath(path);

            // Define loading.msg
            opts.loading.msg = $('<div id="infscr-loading" class="row"><img alt="Loading..." src="' + opts.loading.img + '" /><div class ="loading-text">' + opts.loading.msgText + '</div></div>');

            // Preload loading.img
            (new Image()).src = opts.loading.img;

            // CUSTOM
            // distance from nav links to bottom
            // computed as: height of the document + top offset of container - top offset of nav link
            //opts.pixelsFromNavToBottom = $(document).height() - $(opts.navSelector).offset().top;
            opts.pixelsFromNavToBottom = 500;

            // determine loading.start actions
            opts.loading.start = opts.loading.start ||
            function () {

                $(opts.navSelector).hide();
                opts.loading.msg.appendTo(opts.loading.selector).fadeIn('fast', function () {
                    beginAjax(opts);
                });
            };

            // determine loading.finished actions
            opts.loading.finished = opts.loading.finished ||
            function () {
                opts.loading.msg.fadeOut('fast');
            };

            // callback loading
            opts.callback = function (instance, data) {
                if ( !! opts.behavior && instance['_callback_' + opts.behavior] !== undefined) {
                    instance['_callback_' + opts.behavior].call($(opts.contentSelector)[0], data);
                }
                if (callback) {
                    callback.call($(opts.contentSelector)[0], data, opts);
                }
            };

            this._setup();

        },

        // Console log wrapper
        _debug: function infscr_debug() {

            if (this.options && this.options.debug) {
                return window.console && console.log.call(console, arguments);
            }

        },

        // find the number to increment in the path.
        _determinepath: function infscr_determinepath(path) {

            var opts = this.options;

            // if behavior is defined and this function is extended, call that instead of default
            if ( !! opts.behavior && this['_determinepath_' + opts.behavior] !== undefined) {
                this['_determinepath_' + opts.behavior].call(this, path);
                return;
            }

            if ( !! opts.pathParse) {

                this._debug('pathParse manual');
                return opts.pathParse();

            } else {
              // get the relative path from the link's href
              // ?page=# is used in Rails pagination
              // also capture the path options (?page=1&something=true&something_else=false)
              var nextPage = $(opts.nextSelector).attr('href');
              var path_options = new Array();
              if (typeof nextPage != 'undefined') {
                var path = nextPage.split('?page=')[0] + '?page=';
                path_options = nextPage.split('&');
                opts.pathOptions = path_options;
                // remove the first element of the split array (the link)
                remove_first_element = path_options.shift();
              };
            }
            this._debug('determinePath', path);
            return path;

        },

        // Custom error
        _error: function infscr_error(xhr) {

            var opts = this.options;

            // if behavior is defined and this function is extended, call that instead of default
            if ( !! opts.behavior && this['_error_' + opts.behavior] !== undefined) {
                this['_error_' + opts.behavior].call(this, xhr);
                return;
            }

            if (xhr !== 'destroy' && xhr !== 'end') {
                xhr = 'unknown';
            }

            this._debug('Error', xhr);

            if (xhr == 'end') {
                this._showdonemsg();
            }

            opts.state.isDone = true;
            opts.state.currPage = 1; // if you need to go back to this instance
            opts.state.isPaused = false;
            this._binding('unbind');

        },

        // Load Callback
        _loadcallback: function infscr_loadcallback(box, data) {
          
            var opts = this.options,
                callback = this.options.callback,
                // GLOBAL OBJECT FOR CALLBACK
                result = (opts.state.isDone) ? 'done' : (!opts.appendCallback) ? 'no-append' : 'append',
                frag;

            // if behavior is defined and this function is extended, call that instead of default
            if ( !! opts.behavior && this['_loadcallback_' + opts.behavior] !== undefined) {
                this['_loadcallback_' + opts.behavior].call(this, box, data);
                return;
            }

            switch (result) {

            case 'done':
                
                this._showdonemsg();
                return false;

                break;

            case 'no-append':
                
                // CUSTOM 
                // append the new data to the end of the last itemSelector
                $(opts.itemSelector).filter(":last").after(data);

                break;

            case 'append':
                
                var children = box.children();

                // if it didn't return anything
                if (children.length == 0) {
                    return this._error('end');
                }


                // use a documentFragment because it works when content is going into a table or UL
                frag = document.createDocumentFragment();
                while (box[0].firstChild) {
                    frag.appendChild(box[0].firstChild);
                }

                this._debug('contentSelector', $(opts.contentSelector)[0])
                $(opts.contentSelector)[0].appendChild(frag);
                // previously, we would pass in the new DOM element as context for the callback
                // however we're now using a documentfragment, which doesnt havent parents or children,
                // so the context is the contentContainer guy, and we pass in an array
                //   of the elements collected as the first argument.
                data = children.get();


                break;

            }

            // loadingEnd function
            opts.loading.finished.call($(opts.contentSelector)[0], opts)


            // smooth scroll to ease in the new content
            if (opts.animate) {
                var scrollTo = $(window).scrollTop() + $('#infscr-loading').height() + opts.extraScrollPx + 'px';
                $('html,body').animate({
                    scrollTop: scrollTo
                }, 800, function () {
                    opts.state.isDuringAjax = false;
                });
            }

            if (!opts.animate) opts.state.isDuringAjax = false; // once the call is done, we can allow it again.
            callback(this, data);

            // initialize the AddThis buttons that were AJAX'ed in
    				addthis.toolbox('.addthis_toolbox');
    				
    				// add "read more" expander to long posts
    				$('.expandable').expander({
              slicePoint: 300,
              expandPrefix: '... ',
              expandText: 'Read more',
              preserveWords: false,
              userCollapse: false,
              widow: 0
            });
        },

        _nearbottom: function infscr_nearbottom() {

            var opts = this.options,
                pixelsFromWindowBottomToBottom = 0 + $(document).height() - (opts.binder.scrollTop()) - $(window).height();

            // if behavior is defined and this function is extended, call that instead of default
            if ( !! opts.behavior && this['_nearbottom_' + opts.behavior] !== undefined) {
                this['_nearbottom_' + opts.behavior].call(this);
                return;
            }

            this._debug('math:', 'pixels from window bottom to bottom = ' + pixelsFromWindowBottomToBottom, 'pixels from nav to bottom = ' +  opts.pixelsFromNavToBottom);

            // if distance remaining in the scroll (including buffer) is less than the orignal nav to bottom....
            return (pixelsFromWindowBottomToBottom - opts.bufferPx < opts.pixelsFromNavToBottom);

        },

        // Pause / temporarily disable plugin from firing
        _pausing: function infscr_pausing(pause) {

            var opts = this.options;

            // if behavior is defined and this function is extended, call that instead of default
            if ( !! opts.behavior && this['_pausing_' + opts.behavior] !== undefined) {
                this['_pausing_' + opts.behavior].call(this, pause);
                return;
            }

            // If pause is not 'pause' or 'resume', toggle it's value
            if (pause !== 'pause' && pause !== 'resume' && pause !== null) {
                this._debug('Invalid argument. Toggling pause value instead');
            };

            pause = (pause && (pause == 'pause' || pause == 'resume')) ? pause : 'toggle';

            switch (pause) {
            case 'pause':
                opts.state.isPaused = true;
                break;

            case 'resume':
                opts.state.isPaused = false;
                break;

            case 'toggle':
                opts.state.isPaused = !opts.state.isPaused;
                break;
            }

            this._debug('Paused', opts.state.isPaused);
            return false;

        },

        // Behavior is determined
        // If the behavior option is undefined, it will set to default and bind to scroll
        _setup: function infscr_setup() {

            var opts = this.options;

            // if behavior is defined and this function is extended, call that instead of default
            if ( !! opts.behavior && this['_setup_' + opts.behavior] !== undefined) {
                this['_setup_' + opts.behavior].call(this);
                return;
            }

            this._binding('bind');

            return false;

        },

        // Show done message
        _showdonemsg: function infscr_showdonemsg() {

            var opts = this.options;

            // if behavior is defined and this function is extended, call that instead of default
            if ( !! opts.behavior && this['_showdonemsg_' + opts.behavior] !== undefined) {
                this['_showdonemsg_' + opts.behavior].call(this);
                return;
            }

            opts.loading.msg.find('img').hide().parent().find('div').html(opts.loading.finishedMsg).animate({
                opacity: 1
            }, 50, function () {
                $(this).parent().fadeOut('normal');
            });

            // user provided callback when done    
            opts.errorCallback.call($(opts.contentSelector)[0], 'done');

        },

        // grab each selector option and see if any fail
        _validate: function infscr_validate(opts) {

            for (var key in opts) {
                if (key.indexOf && key.indexOf('Selector') > -1 && $(opts[key]).length === 0) {
                    this._debug('Your ' + key + ' found no elements.');
                    return false;
                }
                return true;
            }

        },

        /*	
        ----------------------------
        Public methods
        ----------------------------
        */

        // Bind to scroll
        bind: function infscr_bind() {
            this._binding('bind');
        },

        // Destroy current instance of plugin
        destroy: function infscr_destroy() {

            this.options.state.isDestroyed = true;
            return this._error('destroy');

        },

        // Set pause value to false
        pause: function infscr_pause() {
            this._pausing('pause');
        },

        // Set pause value to false
        resume: function infscr_resume() {
            this._pausing('resume');
        },

        // Retrieve next set of content items
        retrieve: function infscr_retrieve(pageNum) {

            var instance = this,
                opts = instance.options,
                path = opts.path,
                path_options = opts.path_options,
                box, frag, desturl, method, condition, pageNum = pageNum || null,
                getPage = ( !! pageNum) ? pageNum : opts.state.currPage;
            beginAjax = function infscr_ajax(opts) {

                // increment the URL bit. e.g. /page/3/
                opts.state.currPage++;

                instance._debug('heading into ajax', path);

                // if we're dealing with a table we can't use DIVs
                box = $(opts.contentSelector).is('table') ? $('<tbody/>') : $('<div/>');

                desturl = path + opts.state.currPage  + '&' + opts.pathOptions.join('&');

                method = (opts.dataType == 'html' || opts.dataType == 'json') ? opts.dataType : 'html+callback';
                if (opts.appendCallback && opts.dataType == 'html') method += '+callback'

                switch (method) {

                case 'html+callback':

                    instance._debug('Using HTML via .load() method');
                    box.load(desturl + ' ' + opts.itemSelector, null, function infscr_ajax_callback(responseText) {
                        instance._loadcallback(box, responseText);
                    });

                    break;

                case 'html':
                case 'json':

                    instance._debug('Using ' + (method.toUpperCase()) + ' via $.ajax() method');
                    $.ajax({
                        // params
                        url: desturl,
                        dataType: opts.dataType,
                        complete: function infscr_ajax_callback(jqXHR, textStatus) {
                            condition = (typeof (jqXHR.isResolved) !== 'undefined') ? (jqXHR.isResolved()) : (textStatus === "success" || textStatus === "notmodified");
                            if (condition) {
                              if (jqXHR.responseText.trim().length == 0) {
                                instance._error('end');
                              } else {
                                instance._loadcallback(box, jqXHR.responseText)
                              }
                            } else {
                              instance._error('end');
                            }
                        }
                    });

                    break;
                }
            };

            // if behavior is defined and this function is extended, call that instead of default
            if ( !! opts.behavior && this['retrieve_' + opts.behavior] !== undefined) {
                this['retrieve_' + opts.behavior].call(this, pageNum);
                return;
            }


            // for manual triggers, if destroyed, get out of here
            if (opts.state.isDestroyed) {
                this._debug('Instance is destroyed');
                return false;
            };

            // we dont want to fire the ajax multiple times
            opts.state.isDuringAjax = true;

            opts.loading.start.call($(opts.contentSelector)[0], opts);

        },

        // Check to see next page is needed
        scroll: function infscr_scroll() {

            var opts = this.options,
                state = opts.state;

            // if behavior is defined and this function is extended, call that instead of default
            if ( !! opts.behavior && this['scroll_' + opts.behavior] !== undefined) {
                this['scroll_' + opts.behavior].call(this);
                return;
            }

            if (state.isDuringAjax || state.isInvalidPage || state.isDone || state.isDestroyed || state.isPaused) return;

            if (!this._nearbottom()) return;

            this.retrieve();

        },

        // Toggle pause value
        toggle: function infscr_toggle() {
            this._pausing();
        },

        // Unbind from scroll
        unbind: function infscr_unbind() {
            this._binding('unbind');
        },

        // update options
        update: function infscr_options(key) {
            if ($.isPlainObject(key)) {
                this.options = $.extend(true, this.options, key);
            }
        }

    }


/*	
    ----------------------------
    Infinite Scroll function
    ----------------------------

    Borrowed logic from the following...

    jQuery UI
    - https://github.com/jquery/jquery-ui/blob/master/ui/jquery.ui.widget.js

    jCarousel
    - https://github.com/jsor/jcarousel/blob/master/lib/jquery.jcarousel.js

    Masonry
    - https://github.com/desandro/masonry/blob/master/jquery.masonry.js		

    */

    $.fn.infinitescroll = function infscr_init(options, callback) {


        var thisCall = typeof options;

        switch (thisCall) {

            // method 
        case 'string':

            var args = Array.prototype.slice.call(arguments, 1);

            this.each(function () {

                var instance = $.data(this, 'infinitescroll');

                if (!instance) {
                    // not setup yet
                    // return $.error('Method ' + options + ' cannot be called until Infinite Scroll is setup');
                    return false;
                }
                if (!$.isFunction(instance[options]) || options.charAt(0) === "_") {
                    // return $.error('No such method ' + options + ' for Infinite Scroll');
                    return false;
                }

                // no errors!
                instance[options].apply(instance, args);

            });

            break;

            // creation 
        case 'object':

            this.each(function () {

                var instance = $.data(this, 'infinitescroll');

                if (instance) {

                    // update options of current instance
                    instance.update(options);

                } else {

                    // initialize new instance
                    $.data(this, 'infinitescroll', new $.infinitescroll(options, callback, this));

                }

            });

            break;

        }

        return this;

    };

    /* 
     * smartscroll: debounced scroll event for jQuery *
     * https://github.com/lukeshumard/smartscroll
     * Based on smartresize by @louis_remi: https://github.com/lrbabe/jquery.smartresize.js *
     * Copyright 2011 Louis-Remi & Luke Shumard * Licensed under the MIT license. *
     */

    var event = $.event,
        scrollTimeout;

    event.special.smartscroll = {
        setup: function () {
            $(this).bind("scroll", event.special.smartscroll.handler);
        },
        teardown: function () {
            $(this).unbind("scroll", event.special.smartscroll.handler);
        },
        handler: function (event, execAsap) {
            // Save the context
            var context = this,
                args = arguments;

            // set correct event type
            event.type = "smartscroll";

            if (scrollTimeout) {
                clearTimeout(scrollTimeout);
            }
            scrollTimeout = setTimeout(function () {
                $.event.handle.apply(context, args);
            }, execAsap === "execAsap" ? 0 : 100);
        }
    };

    $.fn.smartscroll = function (fn) {
        return fn ? this.bind("smartscroll", fn) : this.trigger("smartscroll", ["execAsap"]);
    };


})(window, jQuery);


// Converts a date string into date objects
brevidy.convertToDateArray = function(month, day, year) {
	// dateString is formatted as MMMM DD, YYYY
	var d = new Date(month + day + "," + year);
	
	// parse the date using js Date function
	// add 1 to javascript months
	var validMonth = d.getMonth() + 1;
	var validDay = d.getDate();
	var validYear = d.getFullYear();
	
	// return the parsed date as an array
	return {month : validMonth, day : validDay, year : validYear}
};


// Get ISO 8601 time 
// Source: https://developer.mozilla.org/en/Core_JavaScript_1.5_Reference:Global_Objects:Date
brevidy.ISODateString = function(d) {
	function pad(n){return n<10 ? '0'+n : n}
	return d.getUTCFullYear()+'-'
    	+ pad(d.getUTCMonth()+1)+'-'
      	+ pad(d.getUTCDate())+'T'
      	+ pad(d.getUTCHours())+':'
      	+ pad(d.getUTCMinutes())+':'
      	+ pad(d.getUTCSeconds())+'Z'
};