class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def self.eager_load(*associations)
    if associations[0].is_a?(Array) && associations.length == 1
      associations = associations[0]
    end

    associations.map! do |association|
      if association.is_a?(ActionController::Parameters)
        new_association = association.permit!.to_hash.deep_symbolize_keys!
      else
        new_association = association
      end
      new_association
    end

    super(*associations)
  end

  def self.to_correct_json_format(option_parameter)
    if option_parameter.is_a?(ActionController::Parameters)
      return option_parameter.permit!.to_hash.deep_symbolize_keys!
    end
    option_parameter
  end

  def self.dig_key_and_transform_value(hash, target_key, transformed_value)
    hash = hash.to_sym if hash.is_a? String

    case hash
    when Symbol
      return hash == target_key ? {target_key => transformed_value} : hash
    when Array
      return hash.map { |value| self.dig_key_and_transform_value(value, target_key, transformed_value) }
    when Hash
      hash.each do |key, value|
        hash[key] = key == target_key ? transformed_value : self.dig_key_and_transform_value(value, target_key, transformed_value)
      end
      return hash
    end

    return hash
  end

  def self.to_safty_include_option(include_values)
    return nil if include_values.blank?
    self.dig_key_and_transform_value(include_values, :user, {only: :nick_name})
  end

  def to_json_with(option = nil)
    option = self.class.to_correct_json_format(option)
    option[:include] = self.class.to_safty_include_option(option[:include]) if option&.[](:include).present?
    JSON.parse(self.to_json(option))
  end

end
