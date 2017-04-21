require 'spec_helper'

describe 'Factory Method' do
  before :all do
    class TestService
      include SmartIoC::Iocify

      bean :test_service, package: :test

      inject :test_config

      attr_reader :test_config
    end

    class OtherService
      include SmartIoC::Iocify

      bean :other_service, package: :test

      inject :test_config

      attr_reader :test_config
    end

    class TestConfig
      include SmartIoC::Iocify

      bean :test_config, package: :test, factory_method: :build_config

      class Config
      end

      def build_config
        Config.new
      end
    end

    @test_service = SmartIoC.get_bean(:test_service)
    @other_service = SmartIoC.get_bean(:other_service)
  end

  it 'assigns bean with factory method' do
    expect(@test_service.test_config).to be_a(TestConfig::Config)
  end

  it 'assigns bean with factory method' do
    expect(@other_service.test_config).to be_a(TestConfig::Config)
  end

  context 'cross refference factory method beans' do
    before :all do
      class SingletonBean
        include SmartIoC::Iocify
        
        bean :singleton_bean, package: :cross_refference
      end
      
      class FactoryConfig
        include SmartIoC::Iocify
        
        bean :factory_config, factory_method: :build, package: :cross_refference

        inject :singleton_bean

        class Config
          attr_reader :singleton_bean

          def initialize(singleton_bean)
            @singleton_bean = singleton_bean
          end
        end

        def build
          Config.new(singleton_bean)
        end
      end

      class FactoryLogger
        include SmartIoC::Iocify
        
        bean :factory_logger, factory_method: :build, package: :cross_refference

        inject :factory_config

        class Logger
          attr_reader :factory_config

          def initialize(factory_config)
            @factory_config = factory_config
          end
        end
        
        def build
          Logger.new(factory_config)
        end
      end
    end

    it 'creates factory_logger bean' do
      expect(SmartIoC.get_bean(:factory_logger, package: :cross_refference)).to be_a(FactoryLogger::Logger)
    end

    it 'creates factory_config bean' do
      expect(SmartIoC.get_bean(:factory_config, package: :cross_refference)).to be_a(FactoryConfig::Config)
    end
  end
end
