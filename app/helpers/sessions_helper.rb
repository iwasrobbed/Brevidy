module SessionsHelper

  # Stores the request path into a session cookie called :return_to
  def store_location
    session[:return_to] = request.fullpath
  end
  
  # Stores the request path and redirects to the login page to authenticate the user
  # prior to letting them access a certain page
  def deny_access
    store_location
    redirect_to :login, :notice => "Please login to access that page."
  end
  
  # Sets the current_user object and optionally creates a Remember Me cookie
  def sign_in(user)
    cookies.permanent.signed[:remember_token] = [user.id, user.salt]
    self.current_user = user
  end
  
  # Checks if a current_user object has been instantiated or not
  def signed_in?
    !current_user.nil?
  end
  
  # Destroys any Remember Me or session cookies and sets the current_user object to nil
  def sign_out
    cookies.delete(:remember_token)
    session[:remember_token] = [nil, nil]
    self.current_user = nil
  end
  
  # Setter for the current_user object
  def current_user=(user)
    @current_user = user
  end
  
  # Getter for the current_user object 
  # (either from instance variable or Remember Me cookie)
  def current_user
    @current_user ||= user_from_remember_token
  end
  
  # Verifies if a given user is equal to the current_user
  def current_user?(user)
    signed_in? ? user == current_user : false
  end
  
  # Redirects back or to a stored location
  def redirect_back_or(default)
    redirect_to(session[:return_to] || default)
    clear_return_to
  end
  
  # Strips all login params and downcases email field
  # to prepare the params for authentication
  def prepare_params_for_login
    if !params[:email].blank?
      params[:email].strip!
      params[:email].downcase!
    end
    if !params[:password].blank?
      params[:password].strip!
    end
  end
  
  private
    # Authenticates a user from the Remember Me cookie
    def user_from_remember_token
      User.authenticate_with_salt(*remember_token)
    end
    
    # Getter for the Remember Me cookie
    def remember_token
      cookies.signed[:remember_token] || session[:remember_token] || [nil, nil]
    end

    # Clears the return_to session cookie used for storing a path during login
    def clear_return_to
      session[:return_to] = nil
    end
end
