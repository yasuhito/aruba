require 'spec_helper'

RSpec.describe 'File Matchers' do
  include_context 'uses aruba API'
  include_context 'needs to expand paths'

  describe 'to_be_existing_file' do
    let(:name) { @file_name }

    context 'when file exists' do
      before(:each) { create_test_files(name) }

      it { expect(name).to be_existing_file }
    end

    context 'when file does not exist' do
      it { expect(name).not_to be_existing_file }
    end
  end

  describe 'to_be_existing_files' do
    let(:name) { %w(file1.txt file2.txt) }

    context 'when files exists' do
      before(:each) { create_test_files(name) }

      context 'when list of files is given' do
        it { expect(name).to be_existing_files }
      end

      context 'when no list of files is given' do
        let(:name) { 'file1.txt' }
        it { expect(name).not_to be_existing_files }
      end
    end

    context 'when file does not exist' do
      it { expect(name).not_to be_existing_files }
    end
  end

  describe 'to_have_file_content' do
    context 'when file exists' do
      before :each do
        File.write(@file_path, 'aba')
      end

      context 'and file content is exactly equal string ' do
        it { expect(@file_name).to have_file_content('aba') }
      end

      context 'and file content contains string' do
        it { expect(@file_name).to have_file_content(/b/) }
      end

      context 'and file content is not exactly equal string' do
        it { expect(@file_name).not_to have_file_content('c') }
      end

      context 'and file content not contains string' do
        it { expect(@file_name).not_to have_file_content(/c/) }
      end
    end

    context 'when file does not exist' do
      it { expect(@file_name).not_to have_file_content('a') }
    end
  end

  describe 'to_have_file_size' do
    context 'when file exists' do
      before :each do
        File.write(@file_path, '')
      end

      context 'and file size is equal' do
        it { expect(@file_name).to have_file_size(0) }
      end

      context 'and file size is not equal' do
        it { expect(@file_name).not_to have_file_size(1) }
      end
    end

    context 'when file does not exist' do
      it { expect(@file_name).not_to have_file_size(0) }
    end
  end
end
