class AdminsDAO
  include SmartIoC::Iocify

  bean :dao, instance: false

  inject :config

  @data = {}

  class << self
    def insert(entity)
      config.app_name
      @data[entity.id] = entity
    end

    def get(id)
      @data[id]
    end
  end
end
