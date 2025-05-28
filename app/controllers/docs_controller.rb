class DocsController < ApplicationController
  # Docs are publicly accessible - no authentication required
  
  def index
    @docs = docs_structure
  end
  
  def show
    @doc_path = params[:path] || "index"
    @breadcrumbs = build_breadcrumbs(@doc_path)
    
    file_path = Rails.root.join("docs", "#{@doc_path}.md")
    
    unless File.exist?(file_path)
      # Try with index.md in the directory
      dir_path = Rails.root.join("docs", @doc_path, "index.md")
      if File.exist?(dir_path)
        file_path = dir_path
      else
        render_not_found and return
      end
    end
    
    @content = File.read(file_path)
    @title = extract_title(@content) || @doc_path.humanize
    @rendered_content = render_markdown(@content)
  rescue => e
    Rails.logger.error "Error loading docs: #{e.message}"
    render_not_found
  end
  
  private
  
  def docs_structure
    docs_dir = Rails.root.join("docs")
    return {} unless Dir.exist?(docs_dir)
    
    structure = {}
    Dir.glob("#{docs_dir}/**/*.md").each do |file|
      relative_path = Pathname.new(file).relative_path_from(docs_dir).to_s
      path_parts = relative_path.sub(/\.md$/, "").split("/")
      
      current = structure
      path_parts[0..-2].each do |part|
        current[part] ||= {}
        current = current[part]
      end
      current[path_parts.last] = relative_path.sub(/\.md$/, "")
    end
    
    structure
  end
  
  def build_breadcrumbs(path)
    parts = path.split("/")
    breadcrumbs = [{ name: "Docs", path: docs_path, is_link: true }]
    
    current_path = ""
    parts.each_with_index do |part, index|
      current_path = current_path.empty? ? part : "#{current_path}/#{part}"
      
      # Check if this path exists as a file
      file_exists = File.exist?(Rails.root.join("docs", "#{current_path}.md")) ||
                   File.exist?(Rails.root.join("docs", current_path, "index.md"))
      
      # Only make it a link if the file exists, or if it's the current page (last item)
      if file_exists || index == parts.length - 1
        breadcrumbs << { name: part.titleize, path: doc_path(current_path), is_link: true }
      else
        breadcrumbs << { name: part.titleize, path: nil, is_link: false }
      end
    end
    
    breadcrumbs
  end
  
  def extract_title(content)
    lines = content.lines
    title_line = lines.find { |line| line.start_with?("# ") }
    title_line&.sub(/^# /, "")&.strip
  end
  
  def render_markdown(content)
    renderer = Redcarpet::Render::HTML.new(
      filter_html: true,
      no_links: false,
      no_images: false,
      with_toc_data: true,
      hard_wrap: true
    )
    
    markdown = Redcarpet::Markdown.new(
      renderer,
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true,
      lax_spacing: true,
      space_after_headers: true,
      superscript: false
    )
    
    markdown.render(content)
  end
  
  def render_not_found
    render file: "#{Rails.root}/public/404.html", status: :not_found, layout: false
  end
end
