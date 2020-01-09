class Movie < ActiveRecord::Base
  has_many :reviews
  has_many :moviegoers, :through => :reviews

  before_save :capitalize_title
  scope :with_good_reviews, lambda {
    Movie.joins(:reviews).group(:movie_id).having('AVG(reviews.potatoes) > 3')
  }
  scope :for_kids, lambda {
    Movie.where('rating in (?)', %w(G PG))
  }
  scope :recently_reviewed, lambda { |n|
    Movie.joins(:reviews).where(['reviews.created_at >= ?', n.days.ago]).uniq
  }
  
  def capitalize_title
    self.title = self.title.split(/\s+/).map(&:downcase).
      map(&:capitalize).join(' ')
  end
  def self.all_ratings ; %w[G PG PG-13 R NC-17] ; end #  shortcut: array of strings
  validates :title, :presence => true
  validates :release_date, :presence => true
  validate :released_1930_or_later # uses custom validator below
  validates :rating, :inclusion => {:in => Movie.all_ratings},
    :unless => :grandfathered?
  def released_1930_or_later
    errors.add(:release_date, 'must be 1930 or later') if
      release_date && release_date < Date.parse('1 Jan 1930')
  end
  @@grandfathered_date = Date.parse('1 Nov 1968')
  def grandfathered?
    release_date && release_date < @@grandfathered_date
  end
end