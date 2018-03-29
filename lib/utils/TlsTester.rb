require "socket"
require "openssl"

class TlsTester

  def initialize(params)
    # puts "TESTING - SRM"
    # puts(params)
    if params[:uri].nil?
      if not (params[:host].nil? or params[:port].nil?)
        @host = params[:host]
        @port = params[:port]
      else
        raise ArgumentError, '"uri" or "host"/"port" required by TlsTester'
      end
    else
      uri = URI(params[:uri])
      @host = uri.host
      @port = uri.port
    end
  end

  def verifyEnsureProtocol(ssl_version)

    sslClient, tcpSocket = getConnection(ssl_version)

    # attempt the connection and handshake
    begin
      sslClient.connect
    rescue OpenSSL::SSL::SSLError => sslError
      sslClient.close
      tcpSocket.close
      # send the message up with false
      return FALSE, "Caught SSL Error: #{sslError.message}"
    end
    return_message = "Allowed connection with #{sslClient.ssl_version}"
    sslClient.close
    tcpSocket.close

    return TRUE, return_message
  end

  def verifyDenyProtocol(ssl_version, readable_version)

    sslClient, tcpSocket = getConnection(ssl_version)

    # attempt the connection and handshake
    begin
      sslClient.connect
    rescue OpenSSL::SSL::SSLError => sslError
      # Correctly denied the connection
      sslClient.close
      tcpSocket.close
      return TRUE, "Correctly denied connection with #{readable_version}"
    end
    return_message = "Allowed connection with #{sslClient.ssl_version}"
    sslClient.close
    tcpSocket.close
    return FALSE, return_message
  end

  def verifyEnsureTLSv1_2
    #return verifyEnsureProtocol(:TLSv1_2)
    return verifyEnsureProtocol(OpenSSL::SSL::TLS1_2_VERSION)
  end

  def verifyDenyTLSv1()
    return verifyDenyProtocol(OpenSSL::SSL::TLS1_VERSION, "TLSv1.0")
  end

  def verfiyDenySSLv3()
    return verifyDenyProtocol(OpenSSL::SSL::SSL3_VERSION, "SSLv3.0")
  end

  # Ruby and/or OpenSSL won't let us set a max version of SSL2_VERSION
  #def verfiyDenySSLv2()
  #  return TRUE # verifyDenyProtocol(OpenSSL::SSL::SSL2_VERSION)
  #end

  def verfiyDenyTLSv1_1()
    return verifyDenyProtocol(OpenSSL::SSL::TLS1_1_VERSION, "TLSv1.1")
  end

  private
  def getConnection(ssl_version)
    #create a socket
    tcpSocket = TCPSocket.new(@host, @port)

    # set up the SSL context
    sslCtx = OpenSSL::SSL::SSLContext.new
    sslCtx.set_params({verify_mode: OpenSSL::SSL::VERIFY_PEER})
    #sslCtx.set_params.verify_mode = OpenSSL::SSL::VERIFY_PEER
    sslCtx.max_version = ssl_version
    sslCtx.min_version = ssl_version
    # set up the SSL client
    sslClient = OpenSSL::SSL::SSLSocket.new(tcpSocket, sslCtx)
    sslClient.hostname = @host

    return sslClient, tcpSocket
  end

end
