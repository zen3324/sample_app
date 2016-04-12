require 'spec_helper'

describe 'UserPages' do
  subject { page }

  describe 'index' do
    let(:user) { FactoryGirl.create(:user) }
    before(:each) do
      sign_in user
      visit users_path
    end

    it { should have_title(t('title.users')) }
    it { should have_content(t('users.index.all_users')) }

    describe 'pagination' do
      before(:all) { 30.times { FactoryGirl.create(:user) } }
      after(:all) { User.delete_all }

      it { should have_selector('nav.pagination') }

      it 'should list each user' do
        User.page(1).each do |user|
          expect(page).to have_selector('li', text: user.name)
        end
      end
    end

    describe 'delete links' do
      it { should_not have_link(t('users.user.delete')) }

      describe 'as an admin user' do
        let(:admin) { FactoryGirl.create(:admin) }
        before do
          sign_in admin
          visit users_path
        end

        it { should have_link(t('users.user.delete'), href: user_path(User.first)) }
        it 'should be able to delete another user' do
          expect do
            click_link(t('users.user.delete'), match: :first)
          end.to change(User, :count).by(-1)
        end
        it { should_not have_link(t('users.user.delete'), href: user_path(admin)) }
      end
    end
  end

  describe 'profile page' do
    let(:user) { FactoryGirl.create(:user) }
    let!(:m1) { FactoryGirl.create(:micropost, user: user, content: 'Foo') }
    let!(:m2) { FactoryGirl.create(:micropost, user: user, content: 'Bar') }

    before { visit user_path(user) }

    it { should have_content(user.name) }
    it { should have_title(user.name) }

    describe 'microposts' do
      it { should have_content(m1.content) }
      it { should have_content(m2.content) }
      it { should have_content(user.microposts.count) }
    end

    describe "follow/unfollow buttons" do
      let(:other_user) { FactoryGirl.create(:user) }
      before { sign_in user }

      describe "following a user" do
        before { visit user_path(other_user) }

        it "should increment the followed user count" do
          expect do
            click_button t('users.follow.follow')
          end.to change(user.followed_users, :count).by(1)
        end

        it "should increment the other user's followers count" do
          expect do
            click_button t('users.follow.follow')
          end.to change(other_user.followers, :count).by(1)
        end

        describe "toggling the button" do
          before { click_button t('users.follow.follow') }
          it { should have_xpath("//input[@value='#{t('users.unfollow.unfollow')}']") }
        end
      end

      describe "unfollowing a user" do
        before do
          user.follow!(other_user)
          visit user_path(other_user)
        end

        it "should decrement the followed user count" do
          expect do
            click_button t('users.unfollow.unfollow')
          end.to change(user.followed_users, :count).by(-1)
        end

        it "should decrement the other user's follower count" do
          expect do
            click_button t('users.unfollow.unfollow')
          end.to change(other_user.followers, :count).by(-1)
        end

        describe "toggling the button" do
          before { click_button t('users.unfollow.unfollow') }
          it { should have_xpath("//input[@value='#{t('users.follow.follow')}']") }
        end
      end
    end
  end

  describe 'signup page' do
    before { visit signup_path }

    it { should have_content(t('users.new.sign_up')) }
    it { should have_title(full_title(t('title.sign_up'))) }
  end

  describe 'signup' do
    before { visit signup_path }

    let(:submit) { t('users.new.create_my_account') }

    describe 'with invalid information' do
      it 'should not create a user' do
        expect { click_button submit }.not_to change(User, :count)
      end
    end

    describe 'with valid information' do
      before do
        fill_in t('activerecord.attributes.user.name'), with: 'Example User'
        fill_in t('activerecord.attributes.user.email'), with: 'user@example.com'
        fill_in t('activerecord.attributes.user.password'), with: 'foobar'
        fill_in t('activerecord.attributes.user.password_confirmation'), with: 'foobar'
      end

      it 'should create a user' do
        expect { click_button submit }.to change(User, :count).by(1)
      end

      describe 'after saving the user' do
        before { click_button submit }
        let(:user) { User.find_by(email: 'user@example.com') }

        it { should have_link(t('layouts.header.sign_out')) }
        it { should have_title(user.name) }
        it { should have_selector('div.alert.alert-success', text: t('flash.welcome_to_the_sample_app')) }
      end
    end
  end

  describe 'edit' do
    let(:user) { FactoryGirl.create(:user) }
    before do
      sign_in user
      visit edit_user_path(user)
    end

    describe 'page' do
      it { should have_content(t('users.edit.update_your_profile')) }
      it { should have_title(t('title.edit_user')) }
      it { should have_link(t('users.edit.change'), href: 'http://gravatar.com/emails') }
    end

    describe 'with invalid information' do
      before { click_button t('users.edit.save_changes') }

      it { should have_content('error') }
    end

    describe 'with valid information' do
      let(:new_name) { 'New Name' }
      let(:new_email) { 'new@example.com' }
      before do
        fill_in t('activerecord.attributes.user.name'), with: new_name
        fill_in t('activerecord.attributes.user.email'), with: new_email
        fill_in t('activerecord.attributes.user.password'), with: user.password
        fill_in t('activerecord.attributes.user.password_confirmation'), with: user.password
        click_button t('users.edit.save_changes')
      end

      it { should have_title(new_name) }
      it { should have_selector('div.alert.alert-success') }
      it { should have_link(t('layouts.header.sign_out'), href: signout_path) }
      specify { expect(user.reload.name).to eq new_name }
      specify { expect(user.reload.email).to eq new_email }
    end
  end

  describe "following/followers" do
    let(:user) { FactoryGirl.create(:user) }
    let(:other_user) { FactoryGirl.create(:user) }
    before { user.follow!(other_user) }

    describe "followed users" do
      before do
        sign_in user
        visit following_user_path(user)
      end

      it { should have_title(full_title('Following')) }
      it { should have_selector('h3', text: 'Following') }
      it { should have_link(other_user.name, href: user_path(other_user)) }
    end

    describe "followers" do
      before do
        sign_in other_user
        visit followers_user_path(other_user)
      end

      it { should have_title(full_title('Followers')) }
      it { should have_selector('h3', text: 'Followers') }
      it { should have_link(user.name, href: user_path(user)) }
    end
  end
end
