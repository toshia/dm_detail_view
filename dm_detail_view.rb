# -*- coding: utf-8 -*-
miquire :mui, 'retriever_header_widget'

Plugin.create(:dm_detail_view) do
  command(:dm_detail_view_show,
          name: 'ダイレクトメッセージ詳細',
          condition: lambda{ |opt|
            opt.messages.size == 1 and
            opt.messages.first.is_a?(Mikutter::Twitter::DirectMessage) },
          visible: true,
          role: :timeline) do |opt|
    Plugin.call(:show_dm, opt.messages.first)
  end

  on_show_dm do |dm|
    show_dm(dm)
  end

  def show_dm(dm, force=false)
    slug = "dm_detail_view-#{dm.id}".to_sym
    if !force and Plugin::GUI::Tab.exist?(slug)
      Plugin::GUI::Tab.instance(slug).active!
    else
      container = Gtk::RetrieverHeaderWidget.new(dm)
      i_cluster = tab slug, "ダイレクトメッセージ詳細" do
        set_icon Skin.get('message.png')
        set_deletable true
        temporary_tab
        shrink
        nativewidget container
        expand
        cluster nil
      end
      Thread.new {
        Plugin.filtering(:dm_detail_view_fragments, [], i_cluster, dm).first
      }.next { |tabs|
        tabs.each(&:call)
      }.next {
        if !force
          i_cluster.active!
        end
      }
    end
  end

  # [slug] タブスラッグ
  # [title] タブのタイトル
  defdsl :dm_fragment do |slug, title, &proc|
    filter_dm_detail_view_fragments do |tabs, i_cluster, dm|
      tabs << -> do
        fragment_slug = SecureRandom.uuid.to_sym
        i_fragment = Plugin::GUI::Fragment.instance(fragment_slug, title)
        i_cluster << i_fragment
        i_fragment.instance_eval{ @retriever = dm }
        i_fragment.instance_eval_with_delegate(self, &proc)
      end
      [tabs, i_cluster, dm]
    end
  end

  dm_fragment :body, "body" do
    set_icon Skin.get('message.png')
    container = Gtk::HBox.new
    textview = Gtk::IntelligentTextview.new(retriever.to_show)
    vscrollbar = Gtk::VScrollbar.new
    textview.set_scroll_adjustment(nil, vscrollbar.adjustment)
    container.add textview
    container.closeup vscrollbar
    nativewidget container
  end
end
