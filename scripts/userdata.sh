#!/bin/bash
set -euo pipefail

DB_HOST="${db_host}"
DB_NAME="${db_name}"
DB_USER="${db_user}"
DB_PASSWORD="${db_password}"
WP_ADMIN_USER="${wp_admin_user}"
WP_ADMIN_PASSWORD="${wp_admin_password}"
WP_ADMIN_EMAIL="${wp_admin_email}"
WP_PATH="/var/www/html"

yum update -y
amazon-linux-extras enable php8.1
yum clean metadata
yum install -y httpd mariadb php php-mysqlnd php-json php-xml php-mbstring php-cli php-gd php-curl curl tar

systemctl enable httpd
systemctl start httpd

# Wait for RDS to be reachable before configuring WordPress
until mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1" 2>/dev/null; do
  echo "Waiting for RDS at $DB_HOST..."
  sleep 10
done
echo "RDS is ready."

if [ ! -f "$WP_PATH/wp-settings.php" ]; then
  curl -L https://wordpress.org/latest.tar.gz -o /tmp/wordpress.tar.gz
  tar -xzf /tmp/wordpress.tar.gz -C /tmp
  cp -r /tmp/wordpress/* "$WP_PATH/"
fi

SALTS=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)

cat > "$WP_PATH/wp-config.php" <<EOF
<?php
define('DB_NAME', '$DB_NAME');
define('DB_USER', '$DB_USER');
define('DB_PASSWORD', '$DB_PASSWORD');
define('DB_HOST', '$DB_HOST');
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');

define('WP_DEBUG', false);
define('WP_MEMORY_LIMIT', '128M');

define('TECH_NEWS_API_KEY', '');

$SALTS

\$table_prefix = 'wp_';

if ( ! defined('ABSPATH') ) {
  define('ABSPATH', __DIR__ . '/');
}

require_once ABSPATH . 'wp-settings.php';
EOF

mkdir -p "$WP_PATH/wp-content/plugins/auto-tech-news"

cat > "$WP_PATH/wp-content/plugins/auto-tech-news/auto-tech-news.php" <<'PHP'
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
PHP

chown -R apache:apache "$WP_PATH"
find "$WP_PATH" -type d -exec chmod 755 {} \;
find "$WP_PATH" -type f -exec chmod 644 {} \;

curl -L https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp
chmod +x /usr/local/bin/wp

PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
SITE_URL="http://$PUBLIC_IP"

if ! wp core is-installed --path="$WP_PATH" --allow-root; then
  wp core install \
    --path="$WP_PATH" \
    --url="$SITE_URL" \
    --title="Yousuf Gohar Portfolio" \
    --admin_user="$WP_ADMIN_USER" \
    --admin_password="$WP_ADMIN_PASSWORD" \
    --admin_email="$WP_ADMIN_EMAIL" \
    --skip-email \
    --allow-root
fi

wp option update blogname "Yousuf Gohar Portfolio" --path="$WP_PATH" --allow-root
wp option update blogdescription "AWS, Terraform, and cloud engineering. Real projects, practical architecture." --path="$WP_PATH" --allow-root

wp plugin activate auto-tech-news --path="$WP_PATH" --allow-root || true

# Create CV pages and blog posts (idempotent)
ensure_page() {
  local title="$1"
  local content="$2"
  local existing
  existing=$(wp post list --path="$WP_PATH" --allow-root --post_type=page --title="$title" --field=ID --format=ids)
  if [ -z "$existing" ]; then
    wp post create --path="$WP_PATH" --allow-root \
      --post_type=page --post_status=publish \
      --post_title="$title" --post_content="$content"
  fi
}

ensure_post() {
  local title="$1"
  local content="$2"
  local existing
  existing=$(wp post list --path="$WP_PATH" --allow-root --post_type=post --title="$title" --field=ID --format=ids)
  if [ -z "$existing" ]; then
    wp post create --path="$WP_PATH" --allow-root \
      --post_type=post --post_status=publish \
      --post_title="$title" --post_content="$content"
  fi
}

HOMEPAGE_CONTENT="$(cat <<'EOF'
I am Yousuf Gohar, a Cloud and QA Engineer. I build and automate infrastructure on AWS using Terraform and focus on reliable, repeatable deployments.

This site documents real projects: WordPress on EC2 and RDS, VPC design, security groups, and infrastructure as code. The goal is learning by building. Each project here was deployed on AWS with Terraform and is described with architecture notes and tools used.

If you are a recruiter, a cloud engineer, or in QA moving into cloud, you will find practical implementation details and lessons learned from these deployments.
EOF
)"

ABOUT_CONTENT="$(cat <<'EOF'
I work in cloud engineering and quality assurance, with a focus on AWS infrastructure, Terraform, and automation.

My background spans cloud architecture and QA. I am interested in how systems are provisioned, secured, and maintained. I prefer a hands-on approach: design the architecture, write the code, and run it in a real environment. I use AWS for compute, networking, and databases, and Terraform to manage infrastructure as code so that deployments are consistent and repeatable.

I approach problems by breaking them down, checking assumptions, and iterating. This site reflects that: the projects here are real deployments, not tutorials, and the write-ups emphasize what was built and what was learned.
EOF
)"

PROJECTS_CONTENT="$(cat <<'EOF'
WordPress on AWS — Level 1 (EC2 and User Data)

Single EC2 instance runs Apache, PHP, and WordPress. The database was initially local (MariaDB) on the same instance. Provisioning is automated via EC2 user data: packages, WordPress download, and configuration run at first boot. Infrastructure is defined in Terraform: VPC, public and private subnets across two AZs, security groups for HTTP and SSH, and the EC2 instance.

Architecture: One VPC, one public subnet (web server), one private subnet. Internet Gateway and route tables for public access. Security group allows inbound 80 and 22.

Tools: AWS (VPC, EC2, Security Groups), Terraform, bash user data, WordPress.

WordPress on AWS — Level 2 (RDS, Private Subnets)

Same WordPress front end, but the database is moved to Amazon RDS MySQL (Single-AZ). The web server stays on EC2 in a public subnet; RDS lives in a private subnet and is not publicly accessible. A second private subnet in another AZ is used for the RDS subnet group (AWS requirement). A dedicated RDS security group allows inbound 3306 only from the WordPress EC2 security group. User data was updated to remove local MySQL, add a wait loop for RDS availability, and point wp-config.php at the RDS endpoint.

Architecture: VPC with public subnet (EC2), two private subnets (RDS subnet group). DB subnet group, RDS security group, MySQL 8.0 Single-AZ (db.t3.micro, 20 GB). No Multi-AZ, no Secrets Manager; minimal Step 1 upgrade.

Tools: AWS (VPC, EC2, RDS, Security Groups, DB subnet group), Terraform, MySQL 8.0, WordPress.

Terraform-Based AWS Infrastructure

All of the above is managed as code. The Terraform codebase includes modules for network (VPC, subnets, route tables, Internet Gateway), security (security groups), compute (EC2, AMI lookup, user data), and RDS (subnet group, security group, DB instance). State is stored locally; provider is AWS with no hardcoded credentials. The same configuration can be re-applied to recreate or update the stack.

Architecture: Modular Terraform with clear separation of network, security, compute, and database. Variables for region, CIDRs, instance type, and DB credentials; no refactors of existing resource names or state.

Tools: Terraform, AWS Provider, bash (user data).
EOF
)"

BLOG_CONTENT="$(cat <<'EOF'
This blog is for sharing what I learn while building on AWS and Terraform. Posts focus on implementation details, architecture choices, and lessons from real projects.

Topics I cover:

- AWS basics: VPCs, subnets, security groups, and how they fit together
- Cloud architecture: separating web and database, public vs private subnets, single-AZ vs multi-AZ
- QA and cloud: why QA engineers benefit from understanding infrastructure and deployment
- DevOps fundamentals: infrastructure as code, automation, and repeatable environments

The goal is to write clearly for other engineers: what was built, what worked, and what would be done differently next time.
EOF
)"

CONTACT_CONTENT="$(cat <<'EOF'
Yousuf Gohar
Cloud and QA Engineer

Reach out for opportunities in cloud engineering, infrastructure automation, or QA roles with a focus on cloud and reliability.
EOF
)"

ensure_page "Yousuf Gohar" "$HOMEPAGE_CONTENT"
ensure_page "About" "$ABOUT_CONTENT"
ensure_page "Projects" "$PROJECTS_CONTENT"
ensure_page "Blog" "$BLOG_CONTENT"
ensure_page "Contact" "$CONTACT_CONTENT"

ensure_post "Deploying WordPress on EC2 Using User Data" "This post documents the Level 1 setup: a single EC2 instance with Apache, PHP, and WordPress, all provisioned via user data. The database runs locally on the instance (MariaDB). I cover why user data was used, how the script is structured, and how Terraform passes variables into the template. The main takeaway is repeatable infrastructure: the same Terraform and script produce the same environment every time."
ensure_post "AWS Networking Basics Used in This Project" "The project uses a custom VPC with public and private subnets in two Availability Zones. The public subnet has a route to an Internet Gateway; the private subnet does not. Security groups restrict HTTP and SSH to the web server. This post summarizes how the pieces connect and why the split between public and private matters for a later move to RDS."
ensure_post "Why Cloud Skills Matter for QA Professionals" "QA work increasingly touches infrastructure: test environments, CI/CD, and deployment pipelines. Understanding how systems are provisioned and secured helps QA engineers design better tests and spot environment-related failures. This post is for QA professionals who want to learn cloud and DevOps fundamentals without switching roles first."
ensure_post "Moving WordPress from Local MySQL to Amazon RDS" "Level 2 replaces the local database with RDS MySQL in a private subnet. This post describes the changes: DB subnet group, RDS security group allowing 3306 only from the web server, and user data updates (removing local MySQL, waiting for RDS, and pointing wp-config at the RDS endpoint). Lessons: RDS takes several minutes to become available, and the security group must reference the web server SG by ID, not CIDR."
ensure_post "Terraform Modules for a Small AWS Stack" "The Terraform codebase is split into network, security, compute, and RDS modules. Each module has clear inputs and outputs. This post explains how the root module wires them together and why that structure makes it easier to add or change resources without touching unrelated code."
