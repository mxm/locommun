#!/bin/env ruby
# encoding: utf-8
class AnnouncementsController < ApplicationController
  # GET /announcements
  # GET /announcements.json
  def index
    if ! user_signed_in?
      redirect_to root_path
    else
      @my_pates = Dialog.where(:godfather_id => current_user.id)
    end
    @billboards = current_user.billboards
    @billboards += current_user.activated_billboards
    
  end

  # GET /announcements/1
  # GET /announcements/1.json
  def show
    @announcement = Announcement.find(params[:id])
    @billboard = @announcement.billboard
    @json_billboard = @billboard.to_gmaps4rails
    
    generate_map_json @announcement
    respond_to do |format|Billboard.all
      format.html # show.html.erb
      format.json { render json: @announcement }

      format.pdf do
        render :pdf => "flyer", :no_background => false
      end
    end
  end

  # GET /announcements/new
  # GET /announcements/new.json
  def new
    if params[:announcement_id]
      @announcement_old = Announcement.find(params[:announcement_id])
      if Announcement.exists? @announcement_old
        # take the attributes of the old announcements
        @announcement = Announcement.new(:name => @announcement_old.name, :description => @announcement_old.description, :latitude => @announcement_old.latitude, 
                                          :longitude => @announcement_old.longitude, :uj => @announcement_old.uj, :bt=> @announcement_old.bt, :location => @announcement_old.location)
      else
        @announcement = Announcement.new
      end
    else
      @announcement = Announcement.new
    end
    
    if get_stored_object
      @billboard = Billboard.find(get_stored_object)
      @announcement.billboard_id = get_stored_object
      clear_stored_object
    else
      @billboard = Billboard.find(params[:billboard_id])
      @announcement.billboard_id = params[:billboard_id]
    end

    if !user_signed_in?
      deny_access_to_save_object @billboard.id
    return
    end
    @announcement.datetime_type = "no_date"
    @announcement.datetime = DateTime.now

    @json = @announcement.to_gmaps4rails

    if current_user && @announcement.billboard.is_activated?(current_user)
      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @announcement }
      end
    else
      respond_to do |format|
        format.html  { redirect_to(activate_form_billboard_path(@announcement.billboard)) }
      end
    end
  end

  # GET /announcements/1/edit
  def edit
    @announcement = Announcement.find(params[:id])
    @json = @announcement.to_gmaps4rails
    @billboard = @announcement.billboard
    if @announcement.datetime
      @announcement.datetime_type = "date_fixed"
    else
       @announcement.datetime = DateTime.now # For the form
      if @announcement.datetime_module
        @announcement.datetime_type = "date_suggest"
      else
        @announcement.datetime_type = "no_date"
      end
    end
  end

  # POST /announcements
  # POST /announcements.json
  def create
    @announcement = Announcement.new(params[:announcement])
    @billboard = @announcement.billboard
    setdatetime @announcement
    if current_user && @announcement.billboard.is_activated?(current_user)
      @announcement.user = current_user
      @announcement.gmaps = true
      respond_to do |format|
        if @announcement.save
          format.html { redirect_to @announcement, notice: 'Aktivität wurde erfolgreich erstellt.' }
          format.json { render json: @announcement, status: :created, location: @announcement }
        else
          @json = @announcement.to_gmaps4rails
          if !@announcement.datetime
            @announcement.datetime = DateTime.now
          end
          format.html { render action: "new" }
          format.json { render json: @announcement.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  def setdatetime announcement
    case announcement.datetime_type
    when "no_date"
      announcement.datetime_module = false
      announcement.datetime = nil
    when "date_suggest"
      announcement.datetime_module = true
      announcement.datetime = nil
    when "date_fixed"
      announcement.datetime_module = false
      date = params[:date]
      announcement.datetime = DateTime.new date[:year].to_i,date[:month].to_i,date[:day].to_i,date[:hour].to_i,date[:minute].to_i
    end
  end

  # PUT /announcements/1
  # PUT /announcements/1.json
  def update
    @announcement = Announcement.find(params[:id])
    @announcement.assign_attributes(params[:announcement])
    @json = @announcement.to_gmaps4rails
    @billboard = @announcement.billboard
    setdatetime @announcement
    @announcement.gmaps = true
    if(@announcement.user == current_user)
      respond_to do |format|
        if @announcement.save
          format.html { redirect_to @announcement, notice: 'Aktivität wurde erfolgreich geändert.' }
          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @announcement.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # DELETE /announcements/1
  # DELETE /announcements/1.json
  def destroy
    if(@announcement.user == current_user)
      @announcement = Announcement.find(params[:id])
      @announcement.destroy

      respond_to do |format|
        format.html { redirect_to Announcements_url }
        format.json { head :no_content }
      end
    end
  end

  def suggest_date
    @announcement = Announcement.find(params[:id])
    @announcement.date_time_suggestions.create(params[:date_time_suggestion])
    redirect_to @announcement
  end

  def vote_date
    @announcement = Announcement.find(params[:id])
    @date_time_suggestion = DateTimeSuggestion.find(params[:date_time_suggestion_id])
    if !(current_user.voted_on? @date_time_suggestion)
      if params["vote"] == "up"
        current_user.vote_for @date_time_suggestion
      else
        current_user.vote_against @date_time_suggestion
      end
    end
    redirect_to @announcement
  end

  def pick_date
    @announcement = Announcement.find(params[:id])
    @date_time_suggestion = DateTimeSuggestion.find(params[:date_time_suggestion_id])
    if @announcement.user == current_user
    @announcement.datetime = @date_time_suggestion.datetime
    @announcement.datetime_module = false
    @announcement.save
    end
    redirect_to @announcement
  end

end
