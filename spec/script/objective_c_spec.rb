require 'spec_helper'

describe Travis::Build::Script::ObjectiveC do
  let(:options) { { logs: { build: false, state: false } } }
  let(:data)    { PAYLOADS[:push].deep_clone }

  subject { described_class.new(data, options).compile }

  it 'announces xcodebuild -version -sdk' do
    is_expected.to announce 'xcodebuild -version -sdk'
  end

  it 'folds announce' do
    is_expected.to fold 'xcodebuild -version -sdk', 'announce'
  end

  it 'handles ruby version being set' do
    data['config']['rvm'] = 'system'
    is_expected.to setup 'rvm use system'
  end

  it 'sets TRAVIS_XCODE_SDK' do
    data['config']['xcode_sdk'] = 'iphonesimulator7.0'
    is_expected.to set 'TRAVIS_XCODE_SDK', 'iphonesimulator7.0'
  end

  it 'sets TRAVIS_XCODE_SCHEME' do
    data['config']['xcode_scheme'] = 'MyTests'
    is_expected.to set 'TRAVIS_XCODE_SCHEME', 'MyTests'
  end

  it 'sets TRAVIS_XCODE_PROJECT' do
    data['config']['xcode_project'] = 'MyProject.xcodeproj'
    is_expected.to set 'TRAVIS_XCODE_PROJECT', 'MyProject.xcodeproj'
  end

  it 'sets TRAVIS_XCODE_WORKSPACE' do
    data['config']['xcode_workspace'] = 'MyWorkspace.xcworkspace'
    is_expected.to set 'TRAVIS_XCODE_WORKSPACE', 'MyWorkspace.xcworkspace'
  end

  context 'if Podfile exists' do
    before(:each) do
      file('Podfile')
    end

    it 'announces CocoaPods version' do
      is_expected.to announce 'pod --version'
    end

    it 'runs pod install' do
      is_expected.to install 'pod install', retry: true
      store_example 'cocoapods'
    end

    it 'folds pod install' do
      is_expected.to fold 'pod install', 'install'
    end
  end

  context 'if no settings are specified' do
    it 'prints a warning' do
      is_expected.to run /WARNING/
    end
  end

  context 'if workspace and scheme is given' do
    before(:each) do
      data['config']['xcode_workspace'] = 'YourWorkspace.xcworkspace'
      data['config']['xcode_scheme'] = 'YourScheme'
    end

    it 'runs xctool' do
      is_expected.to run_script 'xctool -workspace YourWorkspace.xcworkspace -scheme YourScheme build test'
      store_example 'xctool'
    end
  end

  context 'if project and scheme is given' do
    before(:each) do
      data['config']['xcode_project'] = 'YourProject.xcodeproj'
      data['config']['xcode_scheme'] = 'YourScheme'
    end

    it 'runs xctool' do
      is_expected.to run_script 'xctool -project YourProject.xcodeproj -scheme YourScheme build test'
    end

    context 'if an SDK version is passed' do
      before do
        data['config']['xcode_sdk'] = '7.0'
      end

      it 'passes it to xctool' do
        is_expected.to run_script 'xctool -project YourProject.xcodeproj -scheme YourScheme -sdk 7.0 build test'
      end
    end
  end

  context 'if project is a RubyMotion project' do
    before(:each) do
      file('Rakefile', "require 'motion/project/template/ios'")
    end

    it 'announces RubyMotion version' do
      is_expected.to announce 'motion --version'
    end

    it 'runs specs' do
      is_expected.to run_script 'rake spec'
      store_example 'rubymotion'
    end

    context 'with a Gemfile' do
      before(:each) do
        file('Gemfile')
      end

      it 'runs bundle install' do
        is_expected.to install 'bundle install', retry: true
      end

      it 'folds bundle install' do
        is_expected.to fold 'bundle install', 'install.bundler'
      end

      it 'runs specs with Bundler' do
        is_expected.to run_script 'bundle exec rake spec'
      end
    end
  end
end
