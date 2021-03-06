class DownloadsController < ApplicationController

  require 'rubygems'
  require 'zip'

  def compress(path, archive, replaceTokens)
    FileUtils.mkpath(File.dirname(archive))
    FileUtils.rm archive, :force=>true

    Zip::File.open(archive, Zip::File::CREATE) do |zipfile|
      Dir["#{path}/**/**"].reject{|f|f==archive}.each do |file|

        # If it's a directory just write it out
        if File.directory? file
          zipfile.add(file.sub(path+'/',''), file)

        else
          # Regex compare each replace request
          replaceSelection = nil
          replaceTokens.each do |fName, replaceArray|
            if file =~ fName
              replaceSelection = fName
              break
            end
          end

          # Replace contents with each request
          if replaceSelection != nil
            # Read the file
            contents = nil
            File.open(file, 'r') { |f| contents = f.read }

            p replaceTokens[replaceSelection]
            replaceTokens[replaceSelection].each do |from, to|
              contents = contents.gsub(from, to)
            end

            # Write modified file out to the zip
            zipfile.get_output_stream(file.sub(path+'/','')) { |f| f.print contents }
          else

            # Pass through
            zipfile.add(file.sub(path+'/',''), file)
          end
        end

      end
    end

  end

  def proj
    return if sessionActiveCheckFailed

    paramId = params[:id]

    # find assignment
    userAssignment = UserAssignment.find_or_create(sessionGetUserId, params[:id])
    if userAssignment.nil?
      flash[:error] = 'Failed to find resource.'
      redirect_to(:back)
      return
    end

    resourcePath = File.join(Rails.root, 'app', 'assets', 'assignments', "#{params[:id]}",  params[:path])
    attachmentName = "#{sessionGetUser.lastName} Assignment #{params[:id]}.zip"
    archive = File.join(Rails.root, 'tmp', 'assignments', "#{params[:id]}", "#{params[:path]}.zip")

    compress(resourcePath, archive, {/AuthToken.aat/ =>
                                         { '<AuthToken>' => userAssignment.authToken }})

    # Send-er out!
    send_file(archive, :type => 'application/zip', :filename => attachmentName)
  end

  def flame
    return if sessionActiveCheckFailed

    resourcePath = File.join(Rails.root, 'app', 'assets', 'Flame')
    attachmentName = "#{sessionGetUser.lastName} Flame.zip"
    archive = File.join(Rails.root, 'tmp', 'Flame.zip')

    compress(resourcePath, archive, {/FlameConfig.json/ =>
                             { '<AuthToken>' => sessionGetUser.guid }
                         })

    # Send-er out!
    send_file(archive, :type => 'application/zip', :filename => attachmentName)
  end

end
