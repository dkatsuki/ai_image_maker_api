require 'uri'

class Expantion
end

class String
  def url?
    begin
      uri = URI.parse(self)
      %w(http https).include?(uri.scheme)
    rescue URI::InvalidURIError
      false
    end
  end

	def date_format?
		begin
			!!Date.parse(self)
		rescue => exception
			false
		end
	end

	def number_format?
		self.strip =~ /\A[0-9]+\z/
	end

	def strip # 頭悪すぎるから後でループ処理にして
		self.lstrip.rstrip.gsub(/\A\u00A0+|\u00A0+\z/, '').lstrip.rstrip.gsub(/\A\u00A0+|\u00A0+\z/, '')
	end

	def strip!
		self.replace(self.strip)
		nil
	end

	### 正規表現解説
	# 参考:https://easyramble.com/japanese-regex-with-ruby-oniguruma.html
	# 一-龠々 => 漢字にマッチ（漢字の「一」(いち)から「龠」まで + 々）
	# \p{Hiragana} => ひらがなにマッチ
	# \p{Katakana} => カタカナにマッチ

	def remove_symbolic_character
		# 全&半角数字/全&半角英小&大文字/ひらがな/カタカナ/漢字/ー（長音符）/スペース以外　と　スペース　を消す
		self.gsub(/[^０-９ａ-ｚＡ-Ｚ0-9a-zA-Z一-龠々\p{Hiragana}\p{Katakana}ー']| |　|\'/, '')
	end

	def to_half_width
		# 全角を半角に
		# 長音符はハイフンに
		self.tr('０-９ａ-ｚＡ-Ｚ＋ー', '0-9a-zA-Z+-')
	end

	def hiragana_to_katakana
		NKF.nkf('-W -w --katakana', self)
	end

	def katakana_to_hiragana
		NKF.nkf('-W -w --hiragana', self)
	end

	def to_consistent
		return self.dup if self.blank?
		str = self.to_half_width
		str = str.downcase
		str = str.remove_symbolic_character
		str = str.hiragana_to_katakana
		str.strip
	end

	def to_consistent!
		self.replace(self.to_consistent)
		nil
	end
end

class DateTime
	def minutes_ago(minutes)
		self.ago(minutes * 60)
	end

	def hours_ago(hours)
		self.minutes_ago(hours * 60)
	end
end

class Array
	def has_duplicate_element?
		self.length != self.uniq.length
	end
end