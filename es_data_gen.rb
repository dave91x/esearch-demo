# file: es_data_gen.rb
# date: 8.21.14
# subj: generate the data needed to experiment with elasticsearch setup
# ruby: 2.1.1-p76
# gemset = esearch

# http://www.sitepoint.com/ruby-net-http-library/

require 'ffaker'
require 'json'
require 'active_support'
require 'active_support/core_ext'
require 'active_support/duration'
require 'rest_client'
# require 'net/http'
# require 'uri'

# url = 'http://192.168.1.2:9200/'
# uri = URI.parse(url)
# puts Net::HTTP.get(uri) # GET request
response = RestClient.get 'http://192.168.1.2:9200/'
puts response.code
puts response.headers
puts response.to_str
puts
# RestClient.post "http://example.com/resource", { 'x' => 1 }.to_json, :content_type => :json, :accept => :json

class PatientRecord
  
  attr_accessor :patient_name, :patient_address, :patient_phone, :patient_birthday, :patient_ethnicity, :patient_gender, :doctor, :visit_date, :symptoms, :diagnosis, :prescription, :dosage, :patient_age
  
  def initialize(patient_name, patient_address, patient_phone, patient_birthday, patient_ethnicity, patient_gender, doctor, visit_date, symptoms, diagnosis, prescription, dosage)
    @patient_name = patient_name
    @patient_address = patient_address
    @patient_phone = patient_phone
    @patient_birthday = patient_birthday
    @patient_ethnicity = patient_ethnicity
    @patient_gender = patient_gender
    @doctor = doctor
    @visit_date = visit_date
    @symptoms = symptoms
    @diagnosis = diagnosis
    @prescription = prescription
    @dosage = dosage
    @patient_age = compute_age_from_birthday(patient_birthday)
  end
  
  private
  def compute_age_from_birthday(patient_birthday)
    if patient_birthday
      calc_age = Date.today.year - patient_birthday.year
      calc_age -= 1 if patient_birthday > Date.today.years_ago( calc_age )
      return calc_age
    end
  end
end

def rand_time(from, to=Time.now)
  Time.at(rand_in_range(from.to_f, to.to_f))
end

def rand_in_range(from, to)
  rand * (to - from) + from
end

def rand_addr_gen
  # num = Faker::AddressUS.street_address
  street = Faker::AddressUS.street_address  # + " " + Faker::AddressUS.street_suffix
  city = Faker::AddressUS.city
  state = Faker::AddressUS.state_abbr
  zipcode = Faker::AddressUS.zip_code
  return "#{street}, #{city}, #{state}  #{zipcode}"
end

# generate a list of 50 doctors in this health network
doctor_list = []
50.times do |id|
  drid = "DR" + (id+1).to_s.rjust(5, '0')
  first_name = Faker::Name.first_name
  last_name = Faker::Name.last_name
  full_name = "Dr. #{first_name} #{last_name}, MD"
  name_hash = {  "name" => full_name }
  doctor_list.push(drid)
  puts drid + " ==> " + name_hash.to_json
  r1 = RestClient.put "http://192.168.1.2:9200/hospital/doctor/#{drid}", name_hash.to_json, :content_type => :json, :accept => :json
  puts r1.code
end
  

# puts "=== Doctor List ==="
# doctor_list.each { |d| puts d }

# generate a list of prescription medicine names
med_endings = [ "ical", "itol", "izine", "amine", "apro", "etine" ]
med_list = ["None", "Aspirin", "Motrin", "Aleve"]
20.times do
  med_name = Faker::Lorem.word + med_endings.sample
  med_list.push(med_name.capitalize)
end

# puts
# puts "=== Medicine List ==="
# med_list.each { |d| puts d }

puts

# work on generating patient records
5000.times do |id|
  patient_name = Faker::Name.first_name + " " + Faker::Name.last_name
  patient_address = rand_addr_gen
  patient_phone = Faker::PhoneNumber.short_phone_number
  patient_birthday = rand(6588..29200).days.ago(Date.today)
  patient_ethnicity = Faker::Identification.ethnicity
  patient_gender = Faker::Identification.gender
  doctor = doctor_list.sample
  visit_date = rand_time(365.days.ago, 2.days.ago)
  symptoms = Faker::HealthcareIpsum.paragraphs(3).join("\n\n")
  diagnosis = Faker::HealthcareIpsum.paragraph(4)
  prescription = med_list.sample
  dosage = ( prescription == "None" ) ? "n/a" : "#{rand(50..150)} mg"

  patient_record = PatientRecord.new(patient_name, patient_address, patient_phone, patient_birthday, patient_ethnicity, patient_gender, doctor, visit_date, symptoms, diagnosis, prescription, dosage)
  
  # puts patient_record.to_json
  puts "#{id+1}. #{patient_record.patient_name} - #{patient_record.doctor} - #{patient_record.visit_date} - #{patient_record.patient_age}"
  r2 = RestClient.put "http://192.168.1.2:9200/hospital/visit/#{id+1}", patient_record.to_json, :content_type => :json, :accept => :json
  puts r2.code
end
