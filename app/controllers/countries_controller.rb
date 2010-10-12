# GREENALYTICS
# Countries controller
# It takes care of the database of carbon factors for different countries
# Created by Jorge L. Zapico // jorge@zapi.co // http://jorgezapico.com
# Created for the Center for Sustainable Communications More info at http://cesc.kth.se
# 2010
# Open Source License



class CountriesController < ApplicationController
  # GET /countries
  # GET /countries.xml
  def index
    @countries = Countries.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @countries }
    end
  end

  # GET /countries/1
  # GET /countries/1.xml
  def show
    @countries = Countries.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @countries }
    end
  end

  # GET /countries/new
  # GET /countries/new.xml
  def new
    @countries = Countries.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @countries }
    end
  end

  # GET /countries/1/edit
  def edit
    @countries = Countries.find(params[:id])
  end

  # POST /countries
  # POST /countries.xml
  def create
    @countries = Countries.new(params[:countries])

    respond_to do |format|
      if @countries.save
        flash[:notice] = 'Countries was successfully created.'
        format.html { redirect_to(@countries) }
        format.xml  { render :xml => @countries, :status => :created, :location => @countries }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @countries.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /countries/1
  # PUT /countries/1.xml
  def update
    @countries = Countries.find(params[:id])

    respond_to do |format|
      if @countries.update_attributes(params[:countries])
        flash[:notice] = 'Countries was successfully updated.'
        format.html { redirect_to(@countries) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @countries.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /countries/1
  # DELETE /countries/1.xml
  def destroy
    @countries = Countries.find(params[:id])
    @countries.destroy

    respond_to do |format|
      format.html { redirect_to(countries_url) }
      format.xml  { head :ok }
    end
  end
  
end
