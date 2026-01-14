from services.search_activities import SearchActivities

def test_search_activities_validation():
    result = SearchActivities.run(search_term="")
    assert 'search_term_blank' in result['errors']

def test_search_activities_success():
    result = SearchActivities.run(search_term="Cloud")
    assert result['errors'] is None
    assert len(result['data']) > 0
    assert result['data'][0]['handle'] == 'Alex Grg'