class CustomException < Exception
  attr_accessor :data
  def initialize(data)
    @data = data
  end
end

class RegionController < ApplicationController
  
  def performRequest (uri)
    require 'net/http'
    require 'timeout'
    require 'logger'
    
    url = URI.parse(FiLabInfographics.nodejs + "/monitoring/" + uri)
    req = Net::HTTP.new(url.host, url.port)
    
    req.open_timeout = FiLabInfographics.timeout
    req.read_timeout = FiLabInfographics.timeout
    
    begin
      res = req.get(url.path)
    rescue Timeout::Error
      raise CustomException.new("timeout")
    end
# Logger.info('request');

#    res = Net::HTTP.start(url.host, url.port) { |http| 
#      http.request(req) 
#    } 
  
#     begin
#       res = Net::HTTP.start(url.host, url.port) {|http|
#       http.request(req)
#       }
#     rescue Net::OpenTimeout => e
# 	puts "-----------------"+e.message+"------------------------"
# 	raise e.message
#     end
#   Logger.error(data);   
    
    data = res.body    
    result = JSON.parse(data)
    return result

#  Logger.error(data);
 
    
#     return result ["queryContextResponse"] ["contextResponseList"]
    
  end
  
  def getRegionsData
    #     regionsData = self.performRequest('region')
    regionsData = self.performRequest('regions')
    
    if regionsData != nil
    
      idRegions = [] 
      
  #     regionsData.each do |contextElementResponse|
  #       contextElementResponse["contextElementResponse"].each do |contextElement|   
  # 	contextElement["contextElement"].each do |entityId|
  # 	  entityId["entityId"].each do |id|
  # 	    id["id"].each do |idRegion|
  # 	      idRegions.push(idRegion)
  # 	    end
  # 	  end
  # 	end
  #       end
  #     end

      regionsData["_embedded"]["regions"].each do |region|
		idRegions.push(region["id"])
      end
      
      totValues = Hash.new
      
      totValues["total_nb_users"] = regionsData["total_nb_users"];
      totValues["total_nb_organizations"] = regionsData["total_nb_organizations"];
      totValues["total_nb_cores"] = regionsData["total_nb_cores"];
      totValues["total_nb_ram"] = regionsData["total_nb_ram"];
      totValues["total_nb_disk"] = regionsData["total_nb_disk"];
      totValues["total_nb_vm"] = regionsData["total_nb_vm"];
      
      attributes = Hash.new
      
      idRegions.each do |idRegion|
	regionData = self.performRequest('regions/' + idRegion)
	attributesRegion = Hash.new
	attributesRegion["id"] = regionData["id"]
	attributesRegion["name"] = regionData["name"]
	attributesRegion["country"] = regionData["country"]
	attributesRegion["latitude"] = regionData["latitude"]
	attributesRegion["longitude"] = regionData["longitude"]
	attributesRegion["nb_users"] = regionData["nb_users"]
	attributesRegion["nb_cores"] = regionData["nb_cores"]
	attributesRegion["nb_ram"] = regionData["nb_ram"]
	attributesRegion["nb_disk"] = regionData["nb_disk"]
	attributesRegion["nb_vm"] = regionData["nb_vm"]
	attributes[idRegion] = attributesRegion
      end
      
      totValues["total_regions_count"] = attributes.keys.count;
      
      returnData = Hash.new
      returnData ["regions"] = attributes;
      returnData ["tot"] = totValues;
      
      return returnData;
    end
    return nil
  end
  
  def getRegions

    begin
      regionsData = self.getRegionsData
    rescue CustomException => e
      render :json=>"Problem in retrieving data: "+e.data, :status => :service_unavailable
      return
    end
    
    
    if regionsData == nil
      render :json=>"Problem in retrieving data", :status => :service_unavailable
      return
    end
    render :json => regionsData.to_json
  end
  
  def getServices
    
    begin
      regionsData = self.getRegionsData
    rescue CustomException => e
      render :json=>"Problem in retrieving data: "+e.data, :status => :service_unavailable
      return
    end
    
    if regionsData == nil
      render :json=>"Problem in retrieving data", :status => :service_unavailable
      return
    end
    
    attributesRegionsServices = regionsData["regions"]
    
    
    attributesRegionsServices.each do |key,regionData|
      
      
      
      servicesRegionData = self.performRequest('regions/' + regionData["id"] + '/services')
      
      serviceNova = Hash.new
      serviceNeutron = Hash.new
      serviceCinder = Hash.new
      serviceGlance = Hash.new
      serviceKP = Hash.new
      serviceOverall = Hash.new
      
      serviceNova["value"] = "gray";
      serviceNova["description"] = "";
      
      
      serviceNeutron["value"] = "gray";
      serviceNeutron["description"] = "";
      
      
      serviceCinder["value"] = "gray";
      serviceCinder["description"] = "";
      
      
      serviceGlance["value"] = "gray";
      serviceGlance["description"] = "";
      
      
      serviceKP["value"] = "gray";
      serviceKP["description"] = "";
      
      serviceOverall["value"] = "gray";
      serviceOverall["description"] = "No Messages";
	
      if servicesRegionData != nil &&  
	  servicesRegionData["measures"] != nil && 
	  servicesRegionData["measures"][0] != nil
	
	serviceRegionData = servicesRegionData["measures"][0]
	
	if serviceRegionData["novaServiceStatus"] != nil
	  if serviceRegionData["novaServiceStatus"]["value"] != nil && serviceRegionData["novaServiceStatus"]["value"] != "undefined"
	    serviceNova["value"] = serviceRegionData["novaServiceStatus"]["value"];
	  end
	  if serviceRegionData["novaServiceStatus"]["description"] != nil 
	    serviceNova["description"] = serviceRegionData["novaServiceStatus"]["description"];
	  end
	end
	
	if serviceRegionData["neutronServiceStatus"] != nil
	  if serviceRegionData["neutronServiceStatus"]["value"] != nil && serviceRegionData["neutronServiceStatus"]["value"] != "undefined"
	    serviceNeutron["value"] = serviceRegionData["neutronServiceStatus"]["value"];
	  end
	  if serviceRegionData["neutronServiceStatus"]["description"] != nil
	    serviceNeutron["description"] = serviceRegionData["neutronServiceStatus"]["description"];
	  end
	end
	
	if serviceRegionData["cinderServiceStatus"] != nil
	  if serviceRegionData["cinderServiceStatus"]["value"] != nil && serviceRegionData["cinderServiceStatus"]["value"] != "undefined"
	    serviceCinder["value"] = serviceRegionData["cinderServiceStatus"]["value"];
	  end
	  if serviceRegionData["cinderServiceStatus"]["description"] != nil
	    serviceCinder["description"] = serviceRegionData["cinderServiceStatus"]["description"];
	  end
	end
	
	
	if serviceRegionData["glanceServiceStatus"] != nil
	  if serviceRegionData["glanceServiceStatus"]["value"] != nil && serviceRegionData["glanceServiceStatus"]["value"] != "undefined"
	    serviceGlance["value"] = serviceRegionData["glanceServiceStatus"]["value"];
	  end
	  if serviceRegionData["glanceServiceStatus"]["description"] != nil
	    serviceGlance["description"] = serviceRegionData["glanceServiceStatus"]["description"];
	  end
	end
	
	
	if serviceRegionData["KPServiceStatus"] != nil
	  if serviceRegionData["KPServiceStatus"]["value"] != nil && serviceRegionData["KPServiceStatus"]["value"] != "undefined"
	    serviceKP["value"] = serviceRegionData["KPServiceStatus"]["value"];
	  end
	  if serviceRegionData["KPServiceStatus"]["description"] != nil
	    serviceKP["description"] = serviceRegionData["KPServiceStatus"]["description"];
	  end
	end
	
	
	if serviceRegionData["OverallStatus"] != nil
	  if serviceRegionData["OverallStatus"]["value"] != nil && serviceRegionData["OverallStatus"]["value"] != "undefined"
	    serviceOverall["value"] = serviceRegionData["OverallStatus"]["value"];
	  end
	  if serviceRegionData["OverallStatus"]["description"] != nil
	    serviceOverall["description"] = serviceRegionData["OverallStatus"]["description"];
	  end
	end
	
      end
      
      services = Hash.new
      services["Nova"] = serviceNova;
      services["Neutron"] = serviceNeutron;
      services["Cinder"] = serviceCinder;
      services["Glance"] = serviceGlance;
      services["Keystone P."] = serviceKP;
      services["overallStatus"] = serviceOverall;
      
      regionData["services"] = services;
      
#       attributesRegionsServices[regionData["id"]]["Nova"]["value"] = serviceRegionData["novaServiceStatus"]["value"];
#       attributesRegionsServices[regionData["id"]]["Nova"]["description"] = serviceRegionData["novaServiceStatus"]["description"];
      
#       attributesRegionsServices[regionData["id"]]["Neutron"]["value"] = serviceRegionData["neutronServiceStatus"]["value"];
#       attributesRegionsServices[regionData["id"]]["Neutron"]["description"] = serviceRegionData["neutronServiceStatus"]["description"];

#       attributesRegionsServices[regionData["id"]]["Cinder"]["value"] = serviceRegionData["cinderServiceStatus"]["value"];
#       attributesRegionsServices[regionData["id"]]["Cinder"]["description"] = serviceRegionData["cinderServiceStatus"]["description"];
      
#       attributesRegionsServices[regionData["id"]]["Glance"]["value"] = serviceRegionData["glanceServiceStatus"]["value"];
#       attributesRegionsServices[regionData["id"]]["Glance"]["description"] = serviceRegionData["glanceServiceStatus"]["description"];
      
#       attributesRegionsServices[regionData["id"]]["IDM"]["value"] = serviceRegionData["KPServiceStatus"]["value"];
#       attributesRegionsServices[regionData["id"]]["IDM"]["description"] = serviceRegionData["KPServiceStatus"]["description"];
      
#       points = 0
#       if serviceRegionData["novaServiceStatus"]["value"] == "green"
# 	points+=2;
#       end
# 	
#       if serviceRegionData["neutronServiceStatus"]["value"] == "green"
# 	points+=2;
#       end
# 	
#       if serviceRegionData["cinderServiceStatus"]["value"] == "green"
# 	points+=2;
#       end
# 	
#       if serviceRegionData["glanceServiceStatus"]["value"] == "green" 
# 	points+=2;
#       end
# 	
#       if serviceRegionData["KPServiceStatus"]["value"] == "green" 
# 	points+=2;
#       end
# 	
#       if points == 10 
# 	attributesRegionsServices[regionData["id"]]["services"]["overallStatus"] = "green";
#       elsif points <= 5 
# 	attributesRegionsServices[regionData["id"]]["services"]["overallStatus"] = "red";
#       elsif 
# 	attributesRegionsServices[regionData["id"]]["services"]["overallStatus"] = "yellow";
#       end

    end
#     puts attributesRegionsServices
    render :json => attributesRegionsServices.to_json
      
  end
  
  def getVms
    
    regionsData = self.performRequest('regions')
    
    idRegions = [] 
    
    regionsData.each do |contextElementResponse|
      contextElementResponse["contextElementResponse"].each do |contextElement|   
	contextElement["contextElement"].each do |entityId|
	  entityId["entityId"].each do |id|
	    id["id"].each do |idRegion|
	      idRegions.push(idRegion)
	    end
	  end
	end
      end
    end
    
    attributesRegionsVMs = Hash.new
    
    idRegions.each do |idRegion|
      regionData = self.performRequest('region/' + idRegion)
      
      locationVM = idRegion
      vmsRegionData = self.performRequest('region/' + idRegion + '/VM')
      idVMs = [] 
    
      vmsRegionData.each do |contextElementResponse|
	contextElementResponse["contextElementResponse"].each do |contextElement|   
	  contextElement["contextElement"].each do |entityId|
	    entityId["entityId"].each do |id|
	      id["id"].each do |idVm|
		idVMs.push(idVm)
	      end
	    end
	  end
	end
      end
      
      attributesVMs = Hash.new
      
      idVMs.each do |idVM|
	vmRegionData = self.performRequest('regions/' + idRegion + '/VM/' + idVM)
      
	attributesVM = Hash.new

	vmRegionData.each do |contextElementResponse|
	  contextElementResponse["contextElementResponse"].each do |contextElement|
	    contextElement["contextElement"].each do |contextAttributeList|
	      contextAttributeList["contextAttributeList"].each do |contextAttribute|
		contextAttribute["contextAttribute"].each do |attribute|
		  attributesVM[attribute["name"].first] = attribute["contextValue"].first
		end
	      end
	    end
	  end
	end

	attributesVMs[idVM] = attributesVM

      end
      
      attributesRegionsVMs [locationVM] = attributesVMs
      
    end
    
    render :json => attributesRegionsVMs.to_json
      
  end
  
end