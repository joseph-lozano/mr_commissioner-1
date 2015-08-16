class Team < ActiveRecord::Base
  has_many :player_scores
  belongs_to :league
  has_many :records

  def weekly_scores(week, season=2014)
    # self.player_scores.where(:week_id => get_week_id(week, season)).sum(:points)
    PlayerScore.joins(:week).where("team_id = ? AND weeks.year = ? AND weeks.number = ?", self.id, season, week).sum(:points)
  end

  def best_week(season=2014)
    week = PlayerScore.joins(:week)
    .select("weeks.number, SUM(player_scores.points) as points")
    .where("team_id = ? AND weeks.year = ?", self.id, season)
    .group("player_scores.week_id, weeks.number")
    .order("points DESC")
    .first

    [week.points, week.number]
  end

  def worst_week(season=2014)
    week = PlayerScore.joins(:week)
    .select("weeks.number, SUM(player_scores.points) as points")
    .where("team_id = ? AND weeks.year = ?", self.id, season)
    .group("player_scores.week_id, weeks.number")
    .order("points")
    .first

    [week.points, week.number]
  end

  # def get_all_scores(season=2014)
  #   PlayerScore.joins(:week)
  #   .select("SUM(player_scores.points) as points")
  #   .where("team_id = ? AND weeks.year = ?", self.id, season)
  #   .group("player_scores.week_id")
  # end

  def matchup_count(season = 2014)
    self.league.roster_counts.find_by(year: season).matchup_count
  end

  def season_total(season=2014)
    PlayerScore.joins(:week).where("team_id = ? AND weeks.year = ?", self.id, season).sum(:points)
  end



  def all_play_by_week_wins(week, season=2014)
    PlayerScore.joins(:team).joins(:week)
    .select("teams, SUM(player_scores.points)")
    .where("league_id = ? AND weeks.number = ? AND weeks.year = ?", self.league.id ,week, season)
    .group("player_scores.week_id, teams")
    .having("SUM(player_scores.points) < ?", self.weekly_scores(week, season)).length
  end

  def all_play_by_season_wins(season=2014)
    wins = 0
    matchup_count.times do |w|
      wins += all_play_by_week_wins(w + 1, season)
    end
    wins
  end

  def all_play_by_week_losses(week, season=2014)
    PlayerScore.joins(:team).joins(:week)
    .select("teams, SUM(player_scores.points)")
    .where("league_id = ? AND weeks.number = ? AND weeks.year = ?", self.league.id ,week, season)
    .group("player_scores.week_id, teams")
    .having("SUM(player_scores.points) > ?", self.weekly_scores(week, season)).length
  end

  def all_play_by_season_losses(season=2014)
    losses = 0
    matchup_count.times do |w|
      losses += all_play_by_week_losses(w + 1, season)
    end
    losses
  end

  def all_play_by_week_record(week, season=2014)
    wins = all_play_by_week_wins(week, season)
    losses = all_play_by_week_losses(week, season)
    ties = (self.league.teams.count-1) - (wins + losses)
    "#{wins}-#{losses}-#{ties}"
  end

  def all_play_by_season_record(season=2014)
    wins = all_play_by_season_wins(season)
    losses = all_play_by_season_losses(season)
    ties = ((self.league.teams.count-1) * (self.league.roster_counts.first.matchup_count)) - (wins + losses)
    "#{wins}-#{losses}-#{ties}"
  end

  def all_play_by_week_percentage(week, season=2014)
    (all_play_by_week_wins(week, season).to_f / (self.league.teams.count - 1)).round(3)
  end

  def all_play_by_season_percentage(season=2014)
    (all_play_by_season_wins(season).to_f / ((self.league.teams.count - 1) * self.league.roster_counts.first.matchup_count)).round(3)
  end

  def actual_record(season = 2014)
    record = self.records.find_by(year: season)
    "#{record.wins}-#{record.losses}-#{record.ties}"
  end

  def actual_wins(season = 2014)
    self.records.find_by(year: season).wins
  end

  def average_all_play_wins(season=2014)
    (self.all_play_by_season_wins.to_f / self.matchup_count(season)).round
  end

  def wins_over_average(season = 2014)
    actual_wins(season) - average_all_play_wins(season)
  end

  # 'Luck' Factor

  def luck_factor(wins_over_average)
    case wins_over_average
    when 3..100
      "Super Lucky"
    when 2
      "Very Lucky"
    when 1
      "Lucky"
    when 0
      "No Luck"
    when -1
      "Unlucky"
    when -2
      "Very Unlucky"
    when -100..-3
      "Super Unlucky"
    else
      "NaN"
    end
  end


end
