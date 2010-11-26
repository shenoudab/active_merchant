module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class MigGateway < Gateway
      TEST_URL = 'https://migs.mastercard.com.au/vpcpay'
      LIVE_URL = 'https://migs.mastercard.com.au/vpcpay'

      VIRTUAL_PAYMENT_CLIENT_API_VERION = 1
      
      # The countries the gateway supports merchants from as 2 digit ISO country codes
      self.supported_countries = ['AU','EG']
      
      # The card types supported by the payment gateway
      self.supported_cardtypes = [:visa, :master, :american_express, :discover]
      
      # The homepage URL of the gateway
      self.homepage_url = 'http://www.mastercard.com'
      
      # The name of the gateway
      self.display_name = 'MIGS Gateway'
      
      def initialize(options = {})
        requires!(options, :merchant_id, :access_code)
        if options[:mode] && (options[:mode].to_sym == :production || options[:mode].to_sym == :test)
          self.mode = options[:mode]
        end
        @options = options
        super
      end  
      
      def authorize(money, creditcard, options = {})
        post = {}
        add_invoice(post, options)
        add_creditcard(post, creditcard)
        add_merchant_transaction_id(post, options)
        add_amount(post, money)
        add_address(post, creditcard, options)        
        add_customer_data(post, options)
        
        commit('authonly', money, post)
      end
      
      def purchase(money, creditcard, options = {})
        requires!(options, :invoice, :order_id, :return_url)

        post = {}
        add_invoice(post, options)
        add_creditcard(post, creditcard)
        add_merchant_transaction_id(post, options)
        add_amount(post, money)
        add_address(post, creditcard, options)   
        add_customer_data(post, options)
             
        commit('pay', money, post)
      end 
    
      def capture(money, authorization, options = {})
        commit('capture', money, post)
      end
    
      private                       
      
      def add_customer_data(post, options)
      end

      def add_address(post, creditcard, options)      
      end

      def add_invoice(post, options)
        post[:vpc_TicketNo]  = options[:invoice]
        post[:vpc_OrderInfo] = options[:invoice]
        post[:vpc_ReturnURL] = options[:return_url]
      end

      def add_amount(post, money)
        post[:vpc_Amount] = amount(money)
      end

      def add_creditcard(post, creditcard)
        post[:vpc_CardNum] = creditcard.number
        post[:vpc_CardSecurityCode] = creditcard.verification_value
        post[:vpc_CardExp] = "#{creditcard.year.to_s.last(2)}#{sprintf("%.2i", creditcard.month)}"
      end

      def add_merchant_transaction_id(post, options)
        post[:vpc_MerchTxnRef] = options[:order_id]
      end

      def parse(body)
        params = CGI::parse(body)
        hash = {}
        params.each do|key, value|
          hash[key] = value[0]
        end
        hash
      end     
      
      def commit(action, money, parameters)
        response = parse( ssl_post(GATEWAY_URL, post_data(action, parameters)) )
        authorization = response['vpc_TransactionNo']
        success = (response['vpc_TxnResponseCode'] == '0')
        message = CGI.unescape(response['vpc_Message'])
        Response.new(success, message, response, :authorization => authorization, :test => test?)
      end

      def message_from(response)
      end
      
      def post_data(action, parameters = {})
        parameters[:vpc_Version] = VIRTUAL_PAYMENT_CLIENT_API_VERION
        parameters[:vpc_AccessCode]  = @options[:access_code]
        parameters[:vpc_Merchant]   = @options[:merchant_id]
        parameters[:vpc_Command]   = action
      end
    end
  end
end

