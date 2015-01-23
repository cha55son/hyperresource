require 'test_helper'

SIREN_BODY = {
  'properties' => {
    'page' => 1
  },
  'entities' => [
    {
      'rel' => ['graphs'],
      'properties' => {
        'name' => 'test1'
      },
      'entities' => [
        {
          'class' => ['messages', 'collection'],
          'rel' => ['messages'],
          'href' => '/graphs/test1/messages'
        },
        {
          'class' => ['concepts', 'collection'],
          'rel' => ['concepts'],
          'href' => '/graphs/test2/concepts'
        }
      ],
      'links' => [
        {
          'rel' => ['self'],
          'href' => '/graphs/test1'
        }
      ]
    }
  ],
  'actions' => [
    {
      'name' => 'concepts',
      'method' => 'GET',
      'href' => '/graphs/test1/concepts',
      'title' => 'Get an optionally filtered list of Concepts',
      'type' => 'application/x-www-form-urlencoded',
      'fields' => [
        {
          'name' => 'limit',
          'title' => 'Max number of results in each page',
          'type' => 'NUMBER',
          'required' => false
        },
        {
          'name' => 'page',
          'title' => 'Page number, starting at 1',
          'type' => 'NUMBER',
          'required' => false
        },
        {
          'name' => 'search',
          'title' => 'Keyword search',
          'type' => 'TEXT',
          'required' => true
        }
      ]
    },
    {
      'name' => 'messages',
      'method' => 'GET',
      'href' => '/graphs/test1/messages',
      'title' => 'Get an optionally filtered list of Messages',
      'type' => 'application/x-www-form-urlencoded',
      'fields' => [
        {
          'name' => 'limit',
          'title' => 'Max number of results in each page',
          'type' => 'NUMBER',
          'required' => false
        },
        {
          'name' => 'page',
          'title' => 'Page number, starting at 1',
          'type' => 'NUMBER',
          'required' => false
        },
        {
          'name' => 'search',
          'title' => 'Keyword search',
          'type' => 'TEXT',
          'required' => true
        }
      ]
    }
  ],
  'links' => [
    {
      'rel' => ['self'],
      'href' => '/graphs?limit=1&page=1&order_by=name'
    },
    {
      'rel' => ['next'],
      'href' => '/graphs?limit=1&page=2&order_by=name'
    }
  ]
}
