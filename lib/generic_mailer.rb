require 'net/smtp'
require File.expand_path(File.dirname(__FILE__) + '/../lib/smtp_add_tls_support')

class GenericMailer

  def start( config )
    Net::SMTP.enable_tls() if config["tls"] # Enable TLS for Gmail

    @smtp = Net::SMTP.start(config["address"], 
                           config["port"], 
                           config["domain"], 
                           config["user_name"],
                           config["password"],
                           config["authentication"])
  end

  def send_message( from_addr, to_addrs, subject, body, attachment_file = nil )
    to_addrs = to_addrs.to_a

    if attachment_file
      message = attachment_message( from_addr, to_addrs, subject, body, attachment_file )
    else
      message = simple_message( from_addr, to_addrs, subject, body )
    end

    @smtp.send_message( message, from_addr, to_addrs )
  end

  def finish
    @smtp.finish
  end

  private

  def simple_message( from_addr, to_addrs, subject, body )
    message = <<EOF
From: #{from_addr}
To: #{to_addrs.join(',')}
Subject: #{subject} 
#{body}
EOF
  end

  def attachment_message( from_addr, to_addrs, subject, body, attachment_file )

    # Read a file and encode it into base64 format
    filecontent = File.read(attachment_file)
    encodedcontent = [filecontent].pack("m")   # base64

    marker = "MACHUPICCHUPUMAPUNKU"

    # Define the main headers.
    part1 =<<EOF
From: #{from_addr}
To: #{to_addrs.join(',')}
Subject: #{subject} 
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary=#{marker}
--#{marker}
EOF

    # Define the message action
    part2 =<<EOF
Content-Type: text/plain
Content-Transfer-Encoding:8bit

#{body}
--#{marker}
EOF

    # Define the attachment section
    part3 =<<EOF
Content-Type: multipart/mixed; name=\"#{attachment_file}\"
Content-Transfer-Encoding:base64
Content-Disposition: attachment; filename="#{attachment_file}"

#{encodedcontent}
--#{marker}--
EOF

    message = part1 + part2 + part3
  end


end