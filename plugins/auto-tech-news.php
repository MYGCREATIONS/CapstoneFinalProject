<?php
/*
Plugin Name: Auto Tech News
Description: Fetches technology news via API and publishes posts hourly.
Version: 1.0.0
Author: Your Name
*/

if (!defined('ABSPATH')) {
    exit;
}

define('AUTO_TECH_NEWS_CRON_HOOK', 'auto_tech_news_hourly_event');
define('AUTO_TECH_NEWS_CATEGORY', 'Technology News');

register_activation_hook(__FILE__, 'auto_tech_news_activate');
register_deactivation_hook(__FILE__, 'auto_tech_news_deactivate');

function auto_tech_news_activate() {
    if (!wp_next_scheduled(AUTO_TECH_NEWS_CRON_HOOK)) {
        wp_schedule_event(time() + 300, 'hourly', AUTO_TECH_NEWS_CRON_HOOK);
    }
}

function auto_tech_news_deactivate() {
    $timestamp = wp_next_scheduled(AUTO_TECH_NEWS_CRON_HOOK);
    if ($timestamp) {
        wp_unschedule_event($timestamp, AUTO_TECH_NEWS_CRON_HOOK);
    }
}

add_action(AUTO_TECH_NEWS_CRON_HOOK, 'auto_tech_news_run');

function auto_tech_news_run() {
    $has_api_key = defined('TECH_NEWS_API_KEY') && TECH_NEWS_API_KEY !== '';
    $articles = $has_api_key ? auto_tech_news_fetch_articles() : [];
    if (empty($articles)) {
        $articles = auto_tech_news_dummy_articles();
    }
    if (empty($articles)) {
        return;
    }

    $category_id = auto_tech_news_get_category_id();

    foreach ($articles as $article) {
        $title = isset($article['title']) ? sanitize_text_field($article['title']) : '';
        $summary = isset($article['description']) ? sanitize_text_field($article['description']) : '';
        $url = isset($article['url']) ? esc_url_raw($article['url']) : '';

        if ($title === '' || $summary === '') {
            continue;
        }

        if (auto_tech_news_is_duplicate($title, $url)) {
            continue;
        }

        $post_id = wp_insert_post([
            'post_title'   => $title,
            'post_content' => $summary,
            'post_status'  => 'publish',
            'post_type'    => 'post',
        ], true);

        if (is_wp_error($post_id)) {
            error_log('[AutoTechNews] Failed to insert post: ' . $post_id->get_error_message());
            continue;
        }

        if ($category_id) {
            wp_set_post_categories($post_id, [$category_id]);
        }

        if ($url !== '') {
            update_post_meta($post_id, '_tech_news_source_url', $url);
        }
    }
}

function auto_tech_news_fetch_articles() {
    $endpoint = 'https://newsapi.org/v2/top-headlines';
    $query = [
        'category' => 'technology',
        'language' => 'en',
        'pageSize' => 5,
        'apiKey'   => TECH_NEWS_API_KEY,
    ];

    $url = add_query_arg($query, $endpoint);
    $response = wp_remote_get($url, ['timeout' => 15]);

    if (is_wp_error($response)) {
        error_log('[AutoTechNews] API request error: ' . $response->get_error_message());
        return [];
    }

    $code = wp_remote_retrieve_response_code($response);
    if ($code !== 200) {
        error_log('[AutoTechNews] API request failed with status: ' . $code);
        return [];
    }

    $body = json_decode(wp_remote_retrieve_body($response), true);
    if (!is_array($body) || empty($body['articles'])) {
        return [];
    }

    return $body['articles'];
}

function auto_tech_news_dummy_articles() {
    return [
        [
            'title' => 'AI assistants expand enterprise adoption',
            'description' => 'Organizations continue pilots across support, HR, and analytics with a focus on privacy and governance.',
            'url' => '',
        ],
        [
            'title' => 'Cloud providers roll out cost visibility updates',
            'description' => 'New tooling emphasizes spend transparency and workload optimization for large-scale deployments.',
            'url' => '',
        ],
        [
            'title' => 'Cybersecurity teams prioritize identity protection',
            'description' => 'Security leaders increase investment in MFA, access monitoring, and zero-trust enforcement.',
            'url' => '',
        ],
        [
            'title' => 'Chipmakers announce next-gen efficiency targets',
            'description' => 'Upcoming processors focus on power efficiency and specialized AI acceleration.',
            'url' => '',
        ],
        [
            'title' => 'Data center capacity expands in key regions',
            'description' => 'Operators accelerate new builds to meet AI demand and regional compute needs.',
            'url' => '',
        ],
    ];
}

function auto_tech_news_get_category_id() {
    $term = get_term_by('name', AUTO_TECH_NEWS_CATEGORY, 'category');
    if ($term && !is_wp_error($term)) {
        return (int) $term->term_id;
    }

    $created = wp_insert_term(AUTO_TECH_NEWS_CATEGORY, 'category');
    if (is_wp_error($created)) {
        error_log('[AutoTechNews] Failed to create category: ' . $created->get_error_message());
        return 0;
    }

    return (int) $created['term_id'];
}

function auto_tech_news_is_duplicate($title, $url) {
    if ($url !== '') {
        $existing = get_posts([
            'post_type'   => 'post',
            'meta_key'    => '_tech_news_source_url',
            'meta_value'  => $url,
            'fields'      => 'ids',
            'numberposts' => 1,
        ]);
        if (!empty($existing)) {
            return true;
        }
    }

    $existing_by_title = get_page_by_title($title, OBJECT, 'post');
    return $existing_by_title instanceof WP_Post;
}
