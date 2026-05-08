#!/usr/bin/env ruby

require "cgi"
require "erb"
require "pathname"
require "webrick"
require "yaml"

class PreviewApp
  CONFIG_PATH = "_config.yml"
  STYLE_PATH = "assets/css/style.scss"

  DOCUMENT_TEMPLATE = <<~ERB
    <!doctype html>
    <html lang="<%= h(page["lang"] || site["lang"] || "en") %>">
      <head>
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title><%= h(document_title(page, site)) %></title>
        <meta name="description" content="<%= h((page["description"] || site["description"] || "").to_s.strip) %>">
        <link rel="stylesheet" href="/assets/css/style.css">
      </head>
      <body>
        <a class="skip-link" href="#content">Skip to content</a>
        <%= content_html %>
      </body>
    </html>
  ERB

  HOME_TEMPLATE = <<~ERB
    <header class="site-header" role="banner">
      <nav class="site-nav" aria-label="Primary navigation">
        <a href="#about">About</a>
        <a href="#publications">Publications</a>
        <% if Array(page["working_papers"]).any? %><a href="#working-papers">Working Papers</a><% end %>
      </nav>
    </header>

    <main id="content" class="home-page academic-layout" aria-label="Content">
      <aside class="profile-sidebar" aria-label="Profile">
        <section class="profile-card">
          <div class="profile-card__identity">
            <% if profile["kicker"] %><p class="eyebrow"><%= h(profile["kicker"]) %></p><% end %>
            <h1 id="hero-title"><%= h(profile["name"] || site["title"] || "Home") %></h1>

            <% if profile["role"] || profile["affiliation"] %>
              <div class="profile-role">
                <% if profile["role"] %><p class="profile-role__title"><%= h(profile["role"]) %></p><% end %>
                <% if profile["affiliation"] %>
                  <p class="profile-role__affiliation">
                    <% if profile["affiliation_url"] %>
                      <a href="<%= h(href_for(profile["affiliation_url"])) %>"<%= link_attrs(profile["affiliation_url"]) %>><%= h(profile["affiliation"]) %></a>
                    <% else %>
                      <%= h(profile["affiliation"]) %>
                    <% end %>
                  </p>
                <% end %>
              </div>
            <% end %>
          </div>

          <% if Array(page["research_interests"]).any? %>
            <div class="profile-section">
              <h2 class="profile-section__title">Research Areas</h2>
              <ul class="research-list" aria-label="Research interests">
                <% Array(page["research_interests"]).each do |interest| %>
                  <li><%= h(interest) %></li>
                <% end %>
              </ul>
            </div>
          <% end %>

          <% if Array(page["contact"]).any? %>
            <div class="profile-section">
              <h2 class="profile-section__title">Contact</h2>
              <dl class="contact-list">
                <% Array(page["contact"]).each do |item| %>
                  <div class="contact-item<%= " contact-item--value-only" unless item["label"] %>">
                    <% if item["label"] %><dt><%= h(item["label"]) %></dt><% end %>
                    <dd><%= h(item["value"]) %></dd>
                  </div>
                <% end %>
              </dl>
            </div>
          <% end %>
        </section>
      </aside>

      <div class="content-column">
        <section id="about" class="hero section-block section-block--first" aria-labelledby="about-title">
          <div class="section-heading">
            <h2 id="about-title">About</h2>
          </div>

          <% if profile["bio"] %>
            <div class="hero__bio prose">
              <%= markdown_to_html(profile["bio"]) %>
            </div>
          <% end %>
        </section>

      <% if Array(page["publications"]).any? %>
        <section id="publications" class="section-block" aria-labelledby="publications-title">
          <div class="section-heading">
            <h2 id="publications-title">Publications</h2>
            <% if page["publication_note"] %>
              <div class="section-note prose"><%= markdown_to_html(page["publication_note"]) %></div>
            <% end %>
          </div>

          <% current_year = nil %>
          <ol class="publication-list publication-list--grouped">
            <% Array(page["publications"]).each do |paper| %>
              <% if paper["year"] != current_year %>
                <% current_year = paper["year"] %>
                <li class="publication-year"><%= h(current_year) %></li>
              <% end %>
              <li class="publication-item publication-item--grouped">
                <div class="publication-body">
                  <h3>
                    <% if paper["url"] %>
                      <a href="<%= h(href_for(paper["url"])) %>"<%= link_attrs(paper["url"]) %>><%= h(paper["title"]) %></a>
                    <% else %>
                      <%= h(paper["title"]) %>
                    <% end %>
                  </h3>

                  <% if paper["authors"] %>
                    <p class="publication-authors">
                      <% if paper["author_prefix"] %><%= h(paper["author_prefix"]) %> <% end %><%= h(paper["authors"]) %>
                    </p>
                  <% end %>

                  <% if paper["venue"] || paper["year"] %>
                    <p class="publication-venue"><strong><% if paper["venue"] %><%= h(paper["venue"]) %><% end %><% if paper["year"] %><% if paper["venue"] %> <% end %>(<%= h(paper["year"]) %>)<% end %></strong></p>
                  <% end %>

                  <% if paper["conference_version"] || paper["note"] %>
                    <div class="publication-detail">
                      <% if paper["conference_version"] %><span>Conference version: <strong><%= h(paper["conference_version"]) %></strong></span><% end %>
                      <% if paper["note"] %><span><%= h(paper["note"]) %></span><% end %>
                    </div>
                  <% end %>
                </div>
              </li>
            <% end %>
          </ol>
        </section>
      <% end %>

      <% if Array(page["working_papers"]).any? %>
        <section id="working-papers" class="section-block" aria-labelledby="working-papers-title">
          <div class="section-heading">
            <h2 id="working-papers-title">Working papers</h2>
          </div>

          <ol class="publication-list publication-list--working">
            <% Array(page["working_papers"]).each do |paper| %>
              <li class="publication-item">
                <div class="publication-meta publication-meta--working">
                  <strong>Working paper</strong>
                </div>
                <div class="publication-body">
                  <h3>
                    <% if paper["url"] %>
                      <a href="<%= h(href_for(paper["url"])) %>"<%= link_attrs(paper["url"]) %>><%= h(paper["title"]) %></a>
                    <% else %>
                      <%= h(paper["title"]) %>
                    <% end %>
                  </h3>
                  <% if paper["authors"] %>
                    <p class="publication-authors">
                      <% if paper["author_prefix"] %><%= h(paper["author_prefix"]) %> <% end %><%= h(paper["authors"]) %>
                    </p>
                  <% end %>
                </div>
              </li>
            <% end %>
          </ol>
        </section>
      <% end %>

      <% unless extra_content.empty? %>
        <section class="section-block prose">
          <%= extra_content %>
        </section>
      <% end %>
      </div>
    </main>

    <footer class="site-footer">
      <p>
        <% if page["last_updated"] %>Last updated: <%= h(page["last_updated"]) %>.<% end %>
        &copy; <%= Time.now.year %> <%= h(profile["name"] || site["title"] || "Home") %>.
      </p>
    </footer>
  ERB

  PAGE_TEMPLATE = <<~ERB
    <header class="site-header" role="banner">
      <nav class="site-nav" aria-label="Primary navigation">
        <a href="/">Home</a>
      </nav>
    </header>

    <main id="content" class="page-shell" aria-label="Content">
      <article class="section-block prose">
        <h1><%= h(page["title"] || site["title"] || "Page") %></h1>
        <%= body_html unless body_html.empty? %>
      </article>
    </main>
  ERB

  class Handler < WEBrick::HTTPServlet::AbstractServlet
    def initialize(server, app)
      super(server)
      @app = app
    end

    def do_GET(req, res)
      @app.handle(req, res)
    end

    def do_HEAD(req, res)
      do_GET(req, res)
      res.body = ""
    end
  end

  def initialize(root:, port:)
    @root = Pathname.new(root).expand_path
    @port = port
  end

  def start
    server = WEBrick::HTTPServer.new(
      Port: @port,
      BindAddress: "127.0.0.1",
      AccessLog: [],
      Logger: WEBrick::Log.new($stdout, WEBrick::BasicLog::WARN)
    )
    server.mount "/", Handler, self

    trap("INT") { server.shutdown }
    trap("TERM") { server.shutdown }

    puts "Preview running at http://127.0.0.1:#{@port}"
    puts "Refresh the page after editing Markdown or YAML to see updates."

    server.start
  end

  def handle(req, res)
    path = normalize_path(req.path)

    if path == "/assets/css/style.css"
      serve_style(res)
      return
    end

    file = resolve_request(path)
    if file
      if file.extname == ".md"
        render_markdown(file, res)
      else
        serve_file(file, res)
      end
      return
    end

    render_not_found(res)
  rescue StandardError => error
    render_error(res, error)
  end

  private

  def normalize_path(path)
    clean = WEBrick::HTTPUtils.unescape(path.to_s)
    clean = clean.split("?").first.to_s
    clean = "/" if clean.empty?
    clean = clean.squeeze("/")
    clean.start_with?("/") ? clean : "/#{clean}"
  end

  def resolve_request(path)
    resource = path.sub(%r{\A/}, "").sub(%r{/\z}, "")
    candidates = []

    if resource.empty? || path == "/index.html"
      candidates << @root.join("index.md")
    elsif File.extname(resource).empty?
      candidates << @root.join("#{resource}.md")
      candidates << @root.join(resource, "index.md")
      candidates << @root.join(resource, "index.html")
      candidates << @root.join(resource)
    else
      candidates << @root.join(resource)

      if resource.end_with?("/index.html")
        base = resource.sub(%r{/index\.html\z}, "")
        candidates << @root.join("#{base}.md") unless base.empty?
      end
    end

    candidates.find do |candidate|
      expanded = candidate.expand_path
      expanded.to_s.start_with?(@root.to_s) && expanded.file?
    end
  end

  def render_markdown(file, res)
    page, body = read_front_matter(file)
    site = site_config
    content_html = if page["layout"] == "home" || file.basename.to_s == "index.md"
      render_home(page, body, site)
    else
      render_page(page, body, site)
    end

    res.status = 200
    res["Content-Type"] = "text/html; charset=utf-8"
    res.body = ERB.new(DOCUMENT_TEMPLATE).result(binding)
  end

  def render_home(page, body, site)
    profile = page["profile"] || {}
    extra_content = markdown_to_html(body)
    ERB.new(HOME_TEMPLATE, trim_mode: "-").result(binding)
  end

  def render_page(page, body, site)
    body_html = markdown_to_html(body)
    ERB.new(PAGE_TEMPLATE, trim_mode: "-").result(binding)
  end

  def render_not_found(res)
    page = { "title" => "Not Found", "description" => "Preview page not found" }
    site = site_config
    content_html = render_page(page, "The requested page could not be found in this preview.", site)
    res.status = 404
    res["Content-Type"] = "text/html; charset=utf-8"
    res.body = ERB.new(DOCUMENT_TEMPLATE).result(binding)
  end

  def render_error(res, error)
    page = { "title" => "Preview Error", "description" => "Preview rendering error" }
    site = site_config
    escaped_message = h("#{error.class}: #{error.message}")
    content_html = <<~HTML
      <main id="content" class="page-shell" aria-label="Content">
        <article class="section-block prose">
          <h1>Preview Error</h1>
          <p>#{escaped_message}</p>
        </article>
      </main>
    HTML
    res.status = 500
    res["Content-Type"] = "text/html; charset=utf-8"
    res.body = ERB.new(DOCUMENT_TEMPLATE).result(binding)
  end

  def read_front_matter(file)
    source = file.read
    match = source.match(/\A---\s*\n(.*?)\n---\s*\n/m)
    return [{}, source] unless match

    data = YAML.safe_load(match[1], aliases: true) || {}
    body = source[match.end(0)..] || ""
    [data, body]
  end

  def site_config
    YAML.safe_load(@root.join(CONFIG_PATH).read, aliases: true) || {}
  end

  def serve_style(res)
    stylesheet = @root.join(STYLE_PATH).read.sub(/\A---\s*\n.*?\n---\s*\n/m, "")
    res.status = 200
    res["Content-Type"] = "text/css; charset=utf-8"
    res.body = stylesheet
  end

  def serve_file(file, res)
    extension = file.extname.delete(".")
    res.status = 200
    res["Content-Type"] = WEBrick::HTTPUtils.mime_type(extension, WEBrick::HTTPUtils::DefaultMimeTypes)
    res.body = file.binread
  end

  def document_title(page, site)
    page_title = page["title"] || site["title"]
    return site["title"].to_s if page_title == site["title"]
    [page_title, site["title"]].compact.join(" · ")
  end

  def href_for(url)
    value = url.to_s
    return value if value.start_with?("/", "http://", "https://", "mailto:")

    "/#{value}"
  end

  def link_attrs(url)
    value = url.to_s
    return " target=\"_blank\" rel=\"noopener\"" if value.start_with?("http://", "https://")

    ""
  end

  def markdown_to_html(text)
    source = text.to_s.gsub("\r\n", "\n").strip
    return "" if source.empty?

    blocks = source.split(/\n{2,}/).map(&:strip).reject(&:empty?)
    blocks.map { |block| render_block(block) }.join("\n")
  end

  def render_block(block)
    lines = block.lines.map(&:rstrip)

    if lines.all? { |line| line.lstrip.start_with?("- ", "* ") }
      items = lines.map do |line|
        content = line.sub(/^\s*[-*]\s+/, "")
        "<li>#{inline_markdown(content)}</li>"
      end.join
      "<ul>#{items}</ul>"
    elsif lines.first =~ /\A(#+)\s+(.*)\z/ && Regexp.last_match(1).length <= 6
      level = Regexp.last_match(1).length
      text = Regexp.last_match(2)
      "<h#{level}>#{inline_markdown(text)}</h#{level}>"
    else
      "<p>#{inline_markdown(lines.join(" "))}</p>"
    end
  end

  def inline_markdown(text)
    html = h(text)
    html = html.gsub(/\[([^\]]+)\]\(([^)]+)\)/) do
      label = h(Regexp.last_match(1))
      url = h(Regexp.last_match(2))
      attrs = link_attrs(Regexp.last_match(2))
      %(<a href="#{url}"#{attrs}>#{label}</a>)
    end
    html = html.gsub(/\*\*([^*]+)\*\*/, '<strong>\\1</strong>')
    html.gsub(/\*([^*]+)\*/, '<em>\\1</em>')
  end

  def h(text)
    CGI.escapeHTML(text.to_s)
  end
end

port = Integer(ARGV[0] || ENV.fetch("PORT", "4000"))
PreviewApp.new(root: __dir__, port: port).start