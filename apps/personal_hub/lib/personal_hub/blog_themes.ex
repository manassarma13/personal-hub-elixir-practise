defmodule PersonalHub.BlogThemes do
  @moduledoc """
  Blog theme definitions stored as Elixir maps.
  Each theme defines CSS properties for markdown elements.
  """

  def all do
    [minimal(), hacker(), magazine(), notebook(), neon_nights(), smg_station()]
  end

  def get(id) do
    Enum.find(all(), fn t -> t.id == id end) || minimal()
  end

  def theme_ids, do: Enum.map(all(), & &1.id)

  def minimal do
    %{
      id: "minimal",
      name: "Minimal",
      description: "Clean and elegant with plenty of whitespace",
      styles: %{
        body: "font-family: 'Inter', sans-serif; line-height: 1.8; color: #1a1a2e; background: #fafafa;",
        h1: "font-size: 2.5rem; font-weight: 800; color: #1a1a2e; margin: 2rem 0 1rem; letter-spacing: -0.03em;",
        h2: "font-size: 2rem; font-weight: 700; color: #2d2d44; margin: 1.8rem 0 0.8rem; letter-spacing: -0.02em;",
        h3: "font-size: 1.5rem; font-weight: 600; color: #3d3d5c; margin: 1.5rem 0 0.6rem;",
        h4: "font-size: 1.25rem; font-weight: 600; color: #4d4d6a; margin: 1.2rem 0 0.5rem;",
        h5: "font-size: 1.1rem; font-weight: 600; color: #5d5d78; margin: 1rem 0 0.4rem;",
        h6: "font-size: 1rem; font-weight: 600; color: #6d6d86; margin: 1rem 0 0.4rem;",
        p: "margin: 0.8rem 0; font-size: 1.05rem;",
        a: "color: #6c63ff; text-decoration: underline; text-underline-offset: 3px;",
        strong: "font-weight: 700;",
        em: "font-style: italic;",
        code_inline: "background: #f0f0f5; padding: 2px 6px; border-radius: 4px; font-size: 0.9em; font-family: 'JetBrains Mono', monospace;",
        code_block: "background: #1e1e2e; color: #cdd6f4; padding: 1.5rem; border-radius: 12px; font-size: 0.9rem; font-family: 'JetBrains Mono', monospace; overflow-x: auto; line-height: 1.6;",
        blockquote: "border-left: 4px solid #6c63ff; padding: 1rem 1.5rem; margin: 1.5rem 0; background: #f5f3ff; border-radius: 0 8px 8px 0; color: #4a4a6a;",
        hr: "border: none; height: 1px; background: linear-gradient(to right, transparent, #d1d1e0, transparent); margin: 2.5rem 0;",
        ul: "padding-left: 1.5rem; margin: 1rem 0;",
        ol: "padding-left: 1.5rem; margin: 1rem 0;",
        li: "margin: 0.4rem 0; line-height: 1.7;",
        table: "width: 100%; border-collapse: collapse; margin: 1.5rem 0;",
        th: "background: #f0f0f5; padding: 0.75rem 1rem; text-align: left; font-weight: 600; border-bottom: 2px solid #d1d1e0;",
        td: "padding: 0.75rem 1rem; border-bottom: 1px solid #e8e8f0;",
        img: "max-width: 100%; border-radius: 12px; margin: 1.5rem 0;",
        figure: "margin: 2rem 0; text-align: center;",
        figcaption: "font-size: 0.85rem; color: #888; margin-top: 0.5rem; font-style: italic;"
      }
    }
  end

  def hacker do
    %{
      id: "hacker",
      name: "Hacker",
      description: "Dark terminal aesthetic with green phosphor glow",
      styles: %{
        body: "font-family: 'JetBrains Mono', 'Fira Code', monospace; line-height: 1.7; color: #00ff41; background: #0a0a0a;",
        h1: "font-size: 2.2rem; font-weight: 700; color: #00ff41; margin: 2rem 0 1rem; text-shadow: 0 0 10px rgba(0,255,65,0.3);",
        h2: "font-size: 1.8rem; font-weight: 700; color: #00dd36; margin: 1.5rem 0 0.8rem;",
        h3: "font-size: 1.4rem; font-weight: 600; color: #00cc30; margin: 1.2rem 0 0.6rem;",
        h4: "font-size: 1.2rem; font-weight: 600; color: #00bb2a; margin: 1rem 0 0.5rem;",
        h5: "font-size: 1.1rem; font-weight: 600; color: #00aa25; margin: 1rem 0 0.4rem;",
        h6: "font-size: 1rem; font-weight: 600; color: #009920; margin: 1rem 0 0.4rem;",
        p: "margin: 0.8rem 0; font-size: 0.95rem;",
        a: "color: #00ccff; text-decoration: none; border-bottom: 1px dashed #00ccff;",
        strong: "font-weight: 700; color: #33ff66;",
        em: "font-style: italic; color: #88ff88;",
        code_inline: "background: #1a1a1a; padding: 2px 6px; border-radius: 3px; color: #ffcc00; border: 1px solid #333;",
        code_block: "background: #111; color: #00ff41; padding: 1.5rem; border-radius: 4px; border: 1px solid #1a3a1a; font-size: 0.9rem; overflow-x: auto; line-height: 1.6;",
        blockquote: "border-left: 3px solid #00ff41; padding: 1rem 1.5rem; margin: 1.5rem 0; background: #0d1a0d; color: #88ff88;",
        hr: "border: none; height: 1px; background: #1a3a1a; margin: 2rem 0;",
        ul: "padding-left: 1.5rem; margin: 1rem 0; list-style-type: '> ';",
        ol: "padding-left: 1.5rem; margin: 1rem 0;",
        li: "margin: 0.3rem 0; line-height: 1.6;",
        table: "width: 100%; border-collapse: collapse; margin: 1.5rem 0;",
        th: "background: #1a1a1a; padding: 0.6rem 1rem; text-align: left; font-weight: 700; border: 1px solid #1a3a1a; color: #00ff41;",
        td: "padding: 0.6rem 1rem; border: 1px solid #1a3a1a;",
        img: "max-width: 100%; border-radius: 4px; margin: 1.5rem 0; border: 1px solid #1a3a1a;",
        figure: "margin: 2rem 0; text-align: center;",
        figcaption: "font-size: 0.8rem; color: #557755; margin-top: 0.5rem;"
      }
    }
  end

  def magazine do
    %{
      id: "magazine",
      name: "Magazine",
      description: "Bold editorial style with serif typography",
      styles: %{
        body: "font-family: 'Georgia', 'Times New Roman', serif; line-height: 1.9; color: #2c2c2c; background: #fff;",
        h1: "font-size: 3rem; font-weight: 900; color: #1a1a1a; margin: 2.5rem 0 1rem; letter-spacing: -0.04em; line-height: 1.1;",
        h2: "font-size: 2.2rem; font-weight: 700; color: #c0392b; margin: 2rem 0 0.8rem; border-bottom: 3px solid #c0392b; padding-bottom: 0.3rem;",
        h3: "font-size: 1.6rem; font-weight: 700; color: #2c2c2c; margin: 1.5rem 0 0.6rem;",
        h4: "font-size: 1.3rem; font-weight: 700; color: #444; margin: 1.2rem 0 0.5rem; text-transform: uppercase; letter-spacing: 0.05em; font-size: 0.9rem;",
        h5: "font-size: 1.1rem; font-weight: 700; color: #555; margin: 1rem 0 0.4rem;",
        h6: "font-size: 1rem; font-weight: 700; color: #666; margin: 1rem 0 0.4rem;",
        p: "margin: 1rem 0; font-size: 1.1rem; text-align: justify;",
        a: "color: #c0392b; text-decoration: none; border-bottom: 1px solid #c0392b; transition: color 0.2s;",
        strong: "font-weight: 900;",
        em: "font-style: italic;",
        code_inline: "background: #f8f0e8; padding: 2px 6px; border-radius: 3px; font-family: 'Courier New', monospace; font-size: 0.9em;",
        code_block: "background: #2c2c2c; color: #f8f0e8; padding: 1.5rem; border-radius: 4px; font-family: 'Courier New', monospace; font-size: 0.9rem; overflow-x: auto;",
        blockquote: "border-left: 5px solid #c0392b; padding: 1.5rem 2rem; margin: 2rem 0; background: #fdf6f0; font-style: italic; font-size: 1.2rem; color: #555;",
        hr: "border: none; height: 3px; background: #c0392b; margin: 3rem auto; width: 60px;",
        ul: "padding-left: 1.5rem; margin: 1rem 0;",
        ol: "padding-left: 1.5rem; margin: 1rem 0;",
        li: "margin: 0.5rem 0; line-height: 1.8;",
        table: "width: 100%; border-collapse: collapse; margin: 2rem 0;",
        th: "background: #2c2c2c; color: #fff; padding: 0.8rem 1rem; text-align: left; font-weight: 700; text-transform: uppercase; font-size: 0.8rem; letter-spacing: 0.05em;",
        td: "padding: 0.8rem 1rem; border-bottom: 1px solid #eee;",
        img: "max-width: 100%; margin: 2rem 0;",
        figure: "margin: 2.5rem 0; text-align: center;",
        figcaption: "font-size: 0.85rem; color: #888; margin-top: 0.75rem; font-style: italic; text-align: center;"
      }
    }
  end

  def notebook do
    %{
      id: "notebook",
      name: "Notebook",
      description: "Warm, handwritten feel like a personal journal",
      styles: %{
        body: "font-family: 'Segoe UI', 'Helvetica Neue', sans-serif; line-height: 2; color: #3a3226; background: #fdf6e3; background-image: repeating-linear-gradient(transparent, transparent 31px, #e8dcc8 31px, #e8dcc8 32px);",
        h1: "font-size: 2.2rem; font-weight: 700; color: #5c4033; margin: 2rem 0 1rem;",
        h2: "font-size: 1.8rem; font-weight: 700; color: #6b4c3b; margin: 1.5rem 0 0.8rem;",
        h3: "font-size: 1.4rem; font-weight: 600; color: #7a5c4b; margin: 1.2rem 0 0.6rem;",
        h4: "font-size: 1.2rem; font-weight: 600; color: #8a6c5b; margin: 1rem 0 0.5rem;",
        h5: "font-size: 1.1rem; font-weight: 600; color: #9a7c6b; margin: 1rem 0 0.4rem;",
        h6: "font-size: 1rem; font-weight: 600; color: #aa8c7b; margin: 1rem 0 0.4rem;",
        p: "margin: 0.8rem 0; font-size: 1.05rem;",
        a: "color: #2980b9; text-decoration: underline wavy; text-underline-offset: 4px;",
        strong: "font-weight: 700; color: #5c4033;",
        em: "font-style: italic;",
        code_inline: "background: #eee8d5; padding: 2px 6px; border-radius: 3px; font-family: monospace; font-size: 0.9em;",
        code_block: "background: #3a3226; color: #fdf6e3; padding: 1.5rem; border-radius: 8px; font-family: monospace; font-size: 0.9rem; overflow-x: auto;",
        blockquote: "border-left: 4px solid #d4a574; padding: 1rem 1.5rem; margin: 1.5rem 0; background: rgba(212,165,116,0.1); color: #6b4c3b; border-radius: 0 6px 6px 0;",
        hr: "border: none; height: 2px; background: #d4a574; margin: 2rem 0; opacity: 0.5;",
        ul: "padding-left: 1.5rem; margin: 1rem 0;",
        ol: "padding-left: 1.5rem; margin: 1rem 0;",
        li: "margin: 0.4rem 0; line-height: 2;",
        table: "width: 100%; border-collapse: collapse; margin: 1.5rem 0;",
        th: "background: rgba(212,165,116,0.2); padding: 0.6rem 1rem; text-align: left; font-weight: 700; border-bottom: 2px solid #d4a574;",
        td: "padding: 0.6rem 1rem; border-bottom: 1px solid #e8dcc8;",
        img: "max-width: 100%; border-radius: 8px; margin: 1.5rem 0; box-shadow: 2px 2px 8px rgba(0,0,0,0.1); transform: rotate(-0.5deg);",
        figure: "margin: 2rem 0; text-align: center;",
        figcaption: "font-size: 0.85rem; color: #9a7c6b; margin-top: 0.5rem; font-style: italic;"
      }
    }
  end

  def neon_nights do
    %{
      id: "neon_nights",
      name: "Neon Nights",
      description: "Vibrant cyberpunk dark theme with neon accents",
      styles: %{
        body: "font-family: 'Inter', sans-serif; line-height: 1.8; color: #e0d4f5; background: #0f0b1a;",
        h1: "font-size: 2.5rem; font-weight: 800; color: #ff6ec7; margin: 2rem 0 1rem; text-shadow: 0 0 20px rgba(255,110,199,0.4); letter-spacing: -0.02em;",
        h2: "font-size: 2rem; font-weight: 700; color: #7b68ee; margin: 1.5rem 0 0.8rem; text-shadow: 0 0 15px rgba(123,104,238,0.3);",
        h3: "font-size: 1.5rem; font-weight: 600; color: #00d4ff; margin: 1.2rem 0 0.6rem;",
        h4: "font-size: 1.25rem; font-weight: 600; color: #00ffaa; margin: 1rem 0 0.5rem;",
        h5: "font-size: 1.1rem; font-weight: 600; color: #ffaa00; margin: 1rem 0 0.4rem;",
        h6: "font-size: 1rem; font-weight: 600; color: #ff6b6b; margin: 1rem 0 0.4rem;",
        p: "margin: 0.8rem 0; font-size: 1.05rem;",
        a: "color: #00d4ff; text-decoration: none; border-bottom: 1px solid rgba(0,212,255,0.4); transition: all 0.2s;",
        strong: "font-weight: 700; color: #ff6ec7;",
        em: "font-style: italic; color: #c4b5fd;",
        code_inline: "background: #1a1528; padding: 2px 8px; border-radius: 4px; color: #ffaa00; font-family: 'JetBrains Mono', monospace; font-size: 0.9em; border: 1px solid #2a2040;",
        code_block: "background: #1a1528; color: #e0d4f5; padding: 1.5rem; border-radius: 12px; font-family: 'JetBrains Mono', monospace; font-size: 0.9rem; overflow-x: auto; border: 1px solid #2a2040; line-height: 1.6;",
        blockquote: "border-left: 4px solid #7b68ee; padding: 1rem 1.5rem; margin: 1.5rem 0; background: rgba(123,104,238,0.08); border-radius: 0 12px 12px 0; color: #c4b5fd;",
        hr: "border: none; height: 2px; background: linear-gradient(to right, #ff6ec7, #7b68ee, #00d4ff); margin: 2.5rem 0; border-radius: 1px;",
        ul: "padding-left: 1.5rem; margin: 1rem 0;",
        ol: "padding-left: 1.5rem; margin: 1rem 0;",
        li: "margin: 0.4rem 0; line-height: 1.7;",
        table: "width: 100%; border-collapse: collapse; margin: 1.5rem 0;",
        th: "background: #1a1528; padding: 0.75rem 1rem; text-align: left; font-weight: 700; border-bottom: 2px solid #7b68ee; color: #ff6ec7;",
        td: "padding: 0.75rem 1rem; border-bottom: 1px solid #2a2040;",
        img: "max-width: 100%; border-radius: 12px; margin: 1.5rem 0; border: 1px solid #2a2040;",
        figure: "margin: 2rem 0; text-align: center;",
        figcaption: "font-size: 0.85rem; color: #8878a8; margin-top: 0.5rem; font-style: italic;"
      }
    }
  end

  def smg_station do
    %{
      id: "smg_station",
      name: "SMG Station",
      description: "Clean light-mode design system with soft corners",
      styles: %{
        body: "font-family: 'Inter', sans-serif; line-height: 1.6; color: #1a1a1a; background: #ffffff;",
        h1: "font-size: 2rem; font-weight: 800; color: #111111; margin: 2rem 0 1rem; letter-spacing: -0.04em;",
        h2: "font-size: 1.375rem; font-weight: 700; color: #111111; margin: 1.8rem 0 0.8rem; letter-spacing: -0.02em;",
        h3: "font-size: 1.125rem; font-weight: 600; color: #1a1a1a; margin: 1.5rem 0 0.6rem;",
        h4: "font-size: 1rem; font-weight: 600; color: #484848; margin: 1.2rem 0 0.5rem;",
        h5: "font-size: 0.875rem; font-weight: 600; color: #717171; margin: 1rem 0 0.4rem;",
        h6: "font-size: 0.75rem; font-weight: 700; color: #717171; text-transform: uppercase; letter-spacing: 0.06em; margin: 1rem 0 0.4rem;",
        p: "margin: 0.8rem 0; font-size: 1rem; color: #222222;",
        a: "color: #ff385c; text-decoration: none; border-bottom: 1px solid rgba(255,56,92,0.4);",
        strong: "font-weight: 600; color: #000000;",
        em: "font-style: italic; color: #484848;",
        code_inline: "background: #f7f7f7; padding: 2px 6px; border-radius: 4px; font-family: 'JetBrains Mono', monospace; font-size: 0.85em; border: 1px solid rgba(0,0,0,0.08); color: #ff385c;",
        code_block: "background: #fafafa; color: #1a1a1a; padding: 1.5rem; border-radius: 12px; font-family: 'JetBrains Mono', monospace; font-size: 0.9rem; overflow-x: auto; border: 1px solid rgba(0,0,0,0.08);",
        blockquote: "border-left: 2px solid #ff385c; padding: 1rem 1.5rem; margin: 1.5rem 0; background: #fafafa; color: #484848; border-radius: 0 12px 12px 0;",
        hr: "border: none; height: 1px; background: rgba(0,0,0,0.08); margin: 2rem 0;",
        ul: "padding-left: 1.5rem; margin: 1rem 0; color: #222222;",
        ol: "padding-left: 1.5rem; margin: 1rem 0; color: #222222;",
        li: "margin: 0.4rem 0; line-height: 1.6;",
        table: "width: 100%; border-collapse: collapse; margin: 1.5rem 0;",
        th: "font-size: 0.75rem; font-weight: 600; color: #717171; text-align: left; padding: 12px 16px; border-bottom: 1px solid rgba(0,0,0,0.08);",
        td: "padding: 14px 16px; font-size: 0.875rem; color: #484848; border-bottom: 1px solid rgba(0,0,0,0.08);",
        img: "max-width: 100%; border-radius: 12px; margin: 1.5rem 0; border: 1px solid rgba(0,0,0,0.08); box-shadow: 0 4px 12px rgba(0,0,0,0.05);",
        figure: "margin: 2rem 0; text-align: center;",
        figcaption: "font-size: 0.85rem; color: #717171; margin-top: 0.5rem; font-style: italic;"
      }
    }
  end

  @doc """
  Generates a <style> tag with CSS rules scoped to a .blog-content container,
  applying the given theme's styles to markdown elements.
  """
  def to_scoped_css(%{styles: styles}) do
    rules =
      [
        {".blog-content", styles[:body]},
        {".blog-content h1", styles[:h1]},
        {".blog-content h2", styles[:h2]},
        {".blog-content h3", styles[:h3]},
        {".blog-content h4", styles[:h4]},
        {".blog-content h5", styles[:h5]},
        {".blog-content h6", styles[:h6]},
        {".blog-content p", styles[:p]},
        {".blog-content a", styles[:a]},
        {".blog-content strong", styles[:strong]},
        {".blog-content em", styles[:em]},
        {".blog-content code", styles[:code_inline]},
        {".blog-content pre", styles[:code_block]},
        {".blog-content pre code", "background: none; padding: 0; border: none; border-radius: 0; font-size: inherit;"},
        {".blog-content blockquote", styles[:blockquote]},
        {".blog-content hr", styles[:hr]},
        {".blog-content ul", styles[:ul]},
        {".blog-content ol", styles[:ol]},
        {".blog-content li", styles[:li]},
        {".blog-content table", styles[:table]},
        {".blog-content th", styles[:th]},
        {".blog-content td", styles[:td]},
        {".blog-content img", styles[:img]},
        {".blog-content .blog-figure", styles[:figure]},
        {".blog-content figcaption", styles[:figcaption]},
        {".blog-content .video-embed", "position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; margin: 1.5rem 0; border-radius: 12px;"},
        {".blog-content .video-embed iframe", "position: absolute; top: 0; left: 0; width: 100%; height: 100%;"},
        {".blog-content .audio-embed", "margin: 1.5rem 0;"},
        {".blog-content .audio-embed audio", "width: 100%;"},
        {".blog-content .table-wrapper", "overflow-x: auto; margin: 1.5rem 0;"},
        {".blog-content .code-lang", "display: block; font-size: 0.75rem; color: #888; margin-bottom: -0.5rem; text-transform: uppercase; letter-spacing: 0.05em;"}
      ]
      |> Enum.map(fn {sel, style} -> "#{sel} { #{style || ""} }" end)
      |> Enum.join("\n")

    "<style>#{rules}</style>"
  end
end
