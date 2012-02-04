package org.crix.sample;

import android.app.Activity;
import android.os.Bundle;
import android.view.KeyEvent;
import android.webkit.*;

public class WebSampleActivity extends Activity {
	// ֧�ַ�����һҳ
	@Override
	public boolean onKeyDown(int keyCode, KeyEvent event) {
		// TODO Auto-generated method stub
		if (keyCode == KeyEvent.KEYCODE_BACK && wv.canGoBack()) {
			wv.goBack();
			return true;
		}
			
		return super.onKeyDown(keyCode, event);
	}

	WebView wv;
	
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);
        
        wv = (WebView)findViewById(R.id.webView1);
        wv.getSettings().setJavaScriptEnabled(true);
        wv.loadUrl("http://m.baidu.com");
        wv.setWebViewClient(new WebViewClient() {

        	// �������һ�������������Ӧ�����ӣ����ھ͵ش򿪡�
			@Override
			public boolean shouldOverrideUrlLoading(WebView view, String url) {
				// TODO Auto-generated method stub
				view.loadUrl(url);
				return true;
			}
        	
        });
    }
}