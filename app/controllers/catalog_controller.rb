class CatalogController < ApplicationController
  include BlacklightAdvancedSearch::SolrHelper
  
  # get search results from the solr index
  def index
    # if this in an advanced search we want to instatiate a new QueryParser object
    if params[:search_field] == BlacklightAdvancedSearch.config[:advanced][:search_field]
      @advanced_query = BlacklightAdvancedSearch::QueryParser.new(params,BlacklightAdvancedSearch.config[:advanced])
    end
    
    (@response, @document_list) = get_search_results(@advanced_query ? params.merge(@advanced_query.to_solr) : params)
    @filters = params[:f] || []
    respond_to do |format|
      format.html { save_current_search_params }
      format.rss  { render :layout => false }
    end
    
  end

  protected
  
  # Saves the current search (if it does not already exist) as a models/search object
  # then adds the id of the serach object to session[:history]
  def save_current_search_params
    # Adding in search_field to make sure that we don't automatically return during an advanced search
    # Should this be in the Blacklight plugin itself?
    return if search_session[:q].blank? and search_session[:f].blank? and search_session[:search_field].blank?
    params_copy = search_session.clone # don't think we need a deep copy for this
    params_copy.delete(:page)
    unless @searches.collect { |search| search.query_params }.include?(params_copy)
      new_search = Search.create(:query_params => params_copy)
      session[:history].unshift(new_search.id)
    end
  end

end