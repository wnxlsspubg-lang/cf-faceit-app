package ru.cffaceit.app;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.graphics.Color;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;
import android.webkit.CookieManager;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceError;
import android.webkit.WebResourceRequest;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

/**
 * CF FACEIT — приложение открывает сам сайт, поэтому аккаунт, матчи, лобби,
 * сообщения и уведомления всегда те же, что и на сайте (живая синхронизация).
 */
public class MainActivity extends Activity {
    private static final int FILE_REQ = 7;
    private WebView web;
    private ValueCallback<Uri[]> fileCb;
    private String siteHost;

    @SuppressLint("SetJavaScriptEnabled")
    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);
        siteHost = Uri.parse(BuildConfig.SITE_URL).getHost();

        web = new WebView(this);
        web.setBackgroundColor(Color.parseColor("#0A0507"));
        web.setOverScrollMode(View.OVER_SCROLL_NEVER);
        setContentView(web);

        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);          // вход сохраняется между запусками
        s.setDatabaseEnabled(true);
        s.setMediaPlaybackRequiresUserGesture(false);
        s.setLoadWithOverviewMode(true);
        s.setUseWideViewPort(true);
        s.setSupportZoom(false);
        s.setUserAgentString(s.getUserAgentString() + " CFFaceitApp/Android");

        CookieManager.getInstance().setAcceptCookie(true);
        CookieManager.getInstance().setAcceptThirdPartyCookies(web, true);

        web.setWebViewClient(new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView v, WebResourceRequest r) {
                if (!r.isForMainFrame()) return false;
                Uri u = r.getUrl();
                if (siteHost.equalsIgnoreCase(u.getHost())) return false; // свой сайт — внутри
                openExternal(u);                                          // Telegram, менеджер и т.п.
                return true;
            }

            @Override
            public void onReceivedError(WebView v, WebResourceRequest r, WebResourceError e) {
                if (r.isForMainFrame()) v.loadUrl("file:///android_asset/offline.html");
            }
        });

        web.setWebChromeClient(new WebChromeClient() {
            // Прикрепление скриншотов (выбор из галереи / файлов)
            @Override
            public boolean onShowFileChooser(WebView v, ValueCallback<Uri[]> cb, FileChooserParams p) {
                if (fileCb != null) fileCb.onReceiveValue(null);
                fileCb = cb;
                Intent i = new Intent(Intent.ACTION_GET_CONTENT);
                i.addCategory(Intent.CATEGORY_OPENABLE);
                i.setType("image/*");
                i.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, p.getMode() == FileChooserParams.MODE_OPEN_MULTIPLE);
                try {
                    startActivityForResult(Intent.createChooser(i, "Скриншот"), FILE_REQ);
                } catch (ActivityNotFoundException ex) {
                    fileCb = null;
                    return false;
                }
                return true;
            }
        });

        if (state != null) web.restoreState(state);
        else web.loadUrl(startUrl(getIntent()));
    }

    private String startUrl(Intent intent) {
        Uri data = intent != null ? intent.getData() : null;
        if (data != null && siteHost.equalsIgnoreCase(data.getHost())) return data.toString();
        return BuildConfig.SITE_URL + "/?app=android";
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        if (intent.getData() != null) web.loadUrl(startUrl(intent));
    }

    private void openExternal(Uri u) {
        try {
            startActivity(new Intent(Intent.ACTION_VIEW, u));
        } catch (ActivityNotFoundException ignored) { }
    }

    @Override
    protected void onActivityResult(int req, int res, Intent data) {
        super.onActivityResult(req, res, data);
        if (req != FILE_REQ || fileCb == null) return;
        Uri[] out = null;
        if (res == RESULT_OK && data != null) {
            if (data.getClipData() != null) {
                int n = data.getClipData().getItemCount();
                out = new Uri[n];
                for (int k = 0; k < n; k++) out[k] = data.getClipData().getItemAt(k).getUri();
            } else if (data.getData() != null) {
                out = new Uri[]{data.getData()};
            }
        }
        fileCb.onReceiveValue(out);
        fileCb = null;
    }

    @Override
    public void onBackPressed() {
        if (web.canGoBack()) web.goBack();
        else super.onBackPressed();
    }

    @Override
    protected void onSaveInstanceState(Bundle out) {
        super.onSaveInstanceState(out);
        web.saveState(out);
    }

    @Override
    protected void onPause() {
        super.onPause();
        CookieManager.getInstance().flush();
    }
}
