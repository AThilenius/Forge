class DownloadsController < ApplicationController

  require 'rubygems'
  require 'zip'

  def compress(path, archive, replaceFile, authToken)
    FileUtils.mkpath(File.dirname(archive))
    FileUtils.rm archive, :force=>true

    Zip::File.open(archive, Zip::File::CREATE) do |zipfile|
      Dir["#{path}/**/**"].reject{|f|f==archive}.each do |file|
        if file =~ replaceFile
          contents = File.read(file)
          zipfile.get_output_stream(file.sub(path+'/','')) { |f| f.puts contents.gsub '<AuthToken>', authToken }
        else
          zipfile.add(file.sub(path+'/',''), file)
        end
      end
    end

  end

  def xcode
    # Note: Path is formed as: assets/assignments/:id/:platform
    return if sessionActiveCheckFailed

    paramId = params[:id]

    # find assignment
    userAssignment = UserAssignment.find_or_create(sessionGetUserId, params[:id])
    if userAssignment.nil?
      flash[:error] = 'Failed to find resource.'
      redirect_to(:back)
      return
    end

    resourcePath = File.join(Rails.root, 'app', 'assets', 'assignments', "#{params[:id]}",  'XCode')
    attachmentName = "#{sessionGetUser.lastName} Assignment #{params[:id]}.zip"
    archive = File.join(Rails.root, 'tmp', 'assignments', "#{params[:id]}", 'XCode.zip')

    compress(resourcePath, archive, /Config.h/, userAssignment.authToken)

    # Send-er out!
    send_file(archive, :type => 'application/zip', :filename => attachmentName)
  end

  def vs
    return if sessionActiveCheckFailed

  end

  def makefile
    return if sessionActiveCheckFailed

  end

  def flame
    return if sessionActiveCheckFailed

    resourcePath = File.join(Rails.root, 'app', 'assets', 'Flame')
    attachmentName = "#{sessionGetUser.lastName} Flame.zip"
    archive = File.join(Rails.root, 'tmp', 'Flame.zip')

    compress(resourcePath, archive, /FlameConfig.json/, sessionGetUser.guid)

    # Send-er out!
    send_file(archive, :type => 'application/zip', :filename => attachmentName)
  end

end