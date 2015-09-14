require 'rails_helper'

RSpec.describe UsersController, type: :controller do
	render_views

  describe "GET 'index'" do
	describe "for non-signed-in users" do
		it "should deny access" do
			get :index
			response.should redirect_to(signin_path)
			flash[:notice].should = ~/sign in/i
		end
	end
	describe "for signed-in users" do
		before(:each) do
		@user = test_sign_in(FactoryGirl.create(:user))
		second = FactoryGirl.create(:user, :email => "another@example.com")
		third = FactoryGirl.create(:user, :email => "another@example.net")
		@users = [@user, second, third]
		30.times do
			@users << FactoryGirl.create(:user, :email => FactoryGirl.next(:email))
		end
		end
		it "should be successful" do
			get :index
			response.should be_success
		end
		it "should have the right title" do
			get :index
			expect(response.body).to have_selector("title", :content => "All users")
		end
		it "should have an element for each user" do
			get :index
			@users[0..2].each do |user|
				expect(response.body).to have_selector("li", :content => user.name)
			end
		end
		it "should paginate users" do
			get :index
			expect(response.body).to have_selector("div.pagination")
			expect(response.body).to have_selector("span.disabled", :content => "Previous")
			expect(response.body).to have_selector("a", :href => "/users?page=2",
											:content => "2")
			expect(response.body).to have_selector("a", :href => "/users?page=2",
											:content => "Next")
		end
	end
  end
  describe "GET #show" do
	before(:each) do
	@user = FactoryGirl.create(:user)
    end
	it "should be successful" do
		get :show, :id => @user
		response.should be_success
	end
	it "should find the right user" do
		get :show, :id => @user
		assigns(:user).should == @user
	end
	it "should have the right title" do
		get :show, :id => @user
		expect(response.body).to have_selector("title", :text => @user.name)
		#response{should have_selector("title", :content => @user.name)}
	end
	it "should include the user's name" do
		get :show, :id => @user
		expect(response.body).to have_selector('h1', :text => @user.name)
		#response.should have_selector("h1", :content => @user.name)
	end
	it "should have a profile image" do
		get :show, :id => @user
		expect(response.body).to have_selector('h1>img', :class => "gravatar")
		#response.should have_selector("h1>img", :class => "gravatar")
	end
	it "should show the user's microposts" do
		mp1 = Factory(:micropost, :user => @user, :content => "Foo bar")
		mp2 = Factory(:micropost, :user => @user, :content => "Baz quux")
		get :show, :id => @user
		expect(response.body).to have_selector("span.content", :content => mp1.content)
		expect(response.body).to have_selector("span.content", :content => mp2.content)
	end
  end

  describe "GET #new" do
    it "returns http success" do
		get :new
		expect(response).to have_http_status(:success)
    end
    it "should have the right title" do
		get 'new'
		expect(response.body).to have_selector('title', :text => "Sign up")
		#response.should have_selector("title", :content => "Sign up")
	end
  end
  describe "POST 'create'" do
  	describe "PUT 'update'" do
		before(:each) do
		@user = FactoryGirl.create(:user)
		test_sign_in(@user)
		end
	describe "failure" do
		before(:each) do
		@attr = { :name => "", :email => "", :password => "",
		:password_confirmation => "" }
		end
		it "should not create a user" do
			lambda do
			post :create, :user => @attr
			end.should_not change(User, :count)
		end
		it "should have the right title" do
			post :create, :user => @attr
			expect(response.body).to have_selector("title", :content => "Sign up")
		end
		it "should render the 'new' page" do
			post :create, :user => @attr
			response.should render_template('new')
  		end
	end
	describe "success" do
		before(:each) do
		@attr = { :name => "New User", :email => "user@example.com",
		:password => "foobar", :password_confirmation => "foobar" }
		end
		it "should create a user" do
			lambda do
			post :create, :user => @attr
			end.should change(User, :count).by(1)
		end
		it "should redirect to the user show page" do
			post :create, :user => @attr
			response.should redirect_to(user_path(assigns(:user)))
		end
		it "should have a welcome message" do
			post :create, :user => @attr
			flash[:success].should = ~/welcome to the sample app/i
		end
		it "should sign the user in" do
			post :create, :user => @attr
			controller.should be_signed_in
		end
	end
  end
  	describe "GET 'edit'" do
		before(:each) do
		@user = FactoryGirl.create(:user)
		test_sign_in(@user)
		end
		it "should be successful" do
			get :edit, :id => @user
			response.should be_success
		end
		it "should have the right title" do
			get :edit, :id => @user
			expect(response.body).to have_selector("title", :content => "Edit user")
		end
		it "should have a link to change the Gravatar" do
			get :edit, :id => @user
			gravatar_url = "http://gravatar.com/emails"
			expect(response.body).to have_selector("a", :href => gravatar_url,
			:content => "change")
		end
	end
  end
  	describe "authentication of edit/update pages" do
		before(:each) do
		@user = FactoryGirl.create(:user)
		end
		describe "for non-signed-in users" do
			it "should deny access to 'edit'" do
				get :edit, :id => @user
				response.should redirect_to(signin_path)
			end
			it "should deny access to 'update'" do
				put :update, :id => @user, :user => {}
				response.should redirect_to(signin_path)
			end
		end
		describe "for signed-in users" do
			before(:each) do
			wrong_user = FactoryGirl.create(:user, :email => "user@example.net")
			test_sign_in(wrong_user)
			end
			it "should require matching users for 'edit'" do
				get :edit, :id => @user
				response.should redirect_to(root_path)
			end
			it "should require matching users for 'update'" do
				put :update, :id => @user, :user => {}
				response.should redirect_to(root_path)
			end
		end
	end
	describe "DELETE 'destroy'" do
		before(:each) do
			@user = FactoryGirl.create(:user)
		end
		describe "as a non-signed-in user" do
			it "should deny access" do
				delete :destroy, :id => @user
				response.should redirect_to(signin_path)
			end
		end
		describe "as a non-admin user" do
			it "should protect the page" do
				test_sign_in(@user)
				delete :destroy, :id => @user
				response.should redirect_to(root_path)
			end
		end
		describe "as an admin user" do
			before(:each) do
				admin = FactoryGirl.create(:user, :email => "admin@example.com", :admin => true)
				test_sign_in(admin)
			end
			it "should destroy the user" do
				lambda do
				delete :destroy, :id => @user
				end.should change(User, :count).by(-1)
			end
			it "should redirect to the users page" do
				delete :destroy, :id => @user
				response.should redirect_to(users_path)
			end
		end
	end
end