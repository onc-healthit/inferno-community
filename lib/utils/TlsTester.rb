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
    if params[:acceptedProtocols].nil?
      @acceptedProtocols = [:TLSv1_2]
    else
      @acceptedProtocols = params[:acceptedProtocols]
    end
  end

=begin
  def initialize(host, port, acceptedProtocols)
    @host = host
    @port = port
    @acceptedProtocols = acceptedProtocols
  end

  def initialize(uriString, acceptedProtocols)
    uri = URI(uriString)
    @host = uri.host
    @port = uri.port
    @acceptedProtocols = acceptedProtocols
  end
=end

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

    sslClient.close
    tcpSocket.close
    if sslClient.ssl_version == ssl_version
      return TRUE, "ssl_version in use: #{sslClient.ssl_version}"
    else
      return FALSE, "Connection made with incorrect ssl_version. Specified: #{ssl_version}, connected with #{sslClient.ssl_version}"
    end
  end

  def verifyDenyProtocol(ssl_version)

    sslClient, tcpSocket = getConnection(ssl_version)

    # attempt the connection and handshake
    begin
      sslClient.connect
    rescue OpenSSL::SSL::SSLError => sslError
      sslClient.close
      tcpSocket.close
      return TRUE, "Connection correctly denied with #{ssl_version}"
    end
    if sslClient.ssl_version != ssl_version and @acceptedProtocols.include? sslClient.ssl_version
      return TRUE, "Connection established with an accepted SSL protocol: #{sslClient.ssl_version}"
    else
      return FALSE, "Connection incorrectly made with ssl_version: #{sslClient.ssl_version}"
    end
  end

  def verifyEnsureTLSv1_2
    return verifyEnsureProtocol(:TLSv1_2)
  end

  def verifyDenyTLSv1()
    return verifyDenyProtocol(:TLSv1)
  end

  def verfiyDenySSLv3()
    return verifyDenyProtocol(:SSLv3)
  end

  def verfiyDenyTLSv1_1()
    return verifyDenyProtocol(:TLSv1_1)
  end

  private
  def getConnection(ssl_version)
    #create a socket
    tcpSocket = TCPSocket.new(@host, @port)

    # set up the SSL context
    sslCtx = OpenSSL::SSL::SSLContext.new
    sslCtx.set_params({ssl_version: ssl_version, verify_mode: OpenSSL::SSL::VERIFY_PEER})

    # set up the SSL client
    sslClient = OpenSSL::SSL::SSLSocket.new(tcpSocket, sslCtx)
    sslClient.hostname = @host

    return sslClient, tcpSocket
  end

end
