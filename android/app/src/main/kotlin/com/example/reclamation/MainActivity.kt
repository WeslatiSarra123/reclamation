package com.example.reclamation

import io.flutter.embedding.android.FlutterFragmentActivity
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity

class MainActivity: FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Appliquer un thème compatible ici, si nécessaire
        setTheme(R.style.AppTheme) // Assurez-vous que le thème existe dans styles.xml
    }
}



