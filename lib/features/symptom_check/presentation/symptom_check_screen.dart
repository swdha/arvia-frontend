import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/symptom_bloc.dart';
import '../bloc/symptom_event.dart';
import '../bloc/symptom_state.dart';
import '../data/repositories/symptom_repository.dart';
import '../data/models/symptom_response.dart';

class SymptomCheckScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print('🟣 SymptomCheckScreen building');
    return BlocProvider(
      create: (context) {
        print('🟣 Creating BlocProvider');
        return SymptomBloc(SymptomRepository());
      },
      child: SymptomCheckView(),
    );
  }
}

class SymptomCheckView extends StatefulWidget {
  @override
  State<SymptomCheckView> createState() => _SymptomCheckViewState();
}

class _SymptomCheckViewState extends State<SymptomCheckView> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    print('🟣 SymptomCheckView initialized');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Symptom Checker'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Text(
              'How are you feeling today?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            // Input field
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Describe your symptoms\ne.g. "headache and fever since 2 days"',
                border: OutlineInputBorder(),
              ),
              onChanged: (text) {
                print('🔵 TextField changed: "$text"');
              },
            ),
            SizedBox(height: 16),
            
            // Check button
            ElevatedButton(
              onPressed: () {
                print('🔵 Button clicked!');
                final symptoms = _controller.text.trim();
                print('🔵 Symptoms text: "$symptoms"');
                print('🔵 Symptoms length: ${symptoms.length}');
                
                if (symptoms.isNotEmpty) {
                  print('🔵 Symptoms not empty, sending event to BLoC');
                  try {
                    context.read<SymptomBloc>().add(
                      CheckSymptomsRequested(symptoms),
                    );
                    print('🔵 Event sent successfully!');
                  } catch (e) {
                    print('🔴 Error sending event: $e');
                  }
                } else {
                  print('🔴 Symptoms empty, NOT sending event');
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'Check Symptoms',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            SizedBox(height: 24),
            
            // Results area - listens to state changes
            Expanded(
              child: BlocBuilder<SymptomBloc, SymptomState>(
                builder: (context, state) {
                  print('🔷 BlocBuilder rebuilding with state: ${state.runtimeType}');
                  
                  if (state is SymptomInitial) {
                    print('🔷 Showing Initial state');
                    return Center(
                      child: Text(
                        'Enter your symptoms above',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }
                  
                  if (state is SymptomLoading) {
                    print('🔷 Showing Loading state');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Analyzing your symptoms...',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  if (state is SymptomSuccess) {
                    print('🔷 Showing Success state');
                    final response = state.response;
                    print('🔷 Severity: ${response.severity}');
                    print('🔷 Remedies count: ${response.remedies.length}');
                    
                    // NEW: Call severity-based UI builder
                    return _buildSeverityUI(response);
                  }
                  
                  if (state is SymptomError) {
                    print('🔷 Showing Error state: ${state.message}');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          SizedBox(height: 16),
                          Text(
                            state.message,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.red,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  
                  print('🔷 Unknown state, returning empty container');
                  return Container();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // NEW METHODS BELOW 
  
  // Main method: decides which UI to show based on severity
  Widget _buildSeverityUI(SymptomResponse response) {
    final severity = response.severity.toUpperCase();
    
    if (severity == 'MILD') {
      return _buildMildUI(response);
    } else if (severity == 'MODERATE') {
      return _buildModerateUI(response);
    } else if (severity == 'SEVERE') {
      return _buildSevereUI(response);
    } else {
      return _buildDefaultUI(response);
    }
  }
  
  // MILD UI: Green theme, calm messaging
  Widget _buildMildUI(SymptomResponse response) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Severity badge (green)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Severity: MILD',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          
          // Calm reassurance message
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.green[700]),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Self-care is appropriate. Monitor symptoms and seek care if they worsen.',
                    style: TextStyle(
                      color: Colors.green[900],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          
          // Analysis
          Text(
            'Analysis:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(response.answer, style: TextStyle(fontSize: 16)),
          SizedBox(height: 16),
          
          // Remedies section
          if (response.remedies.isNotEmpty)
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.home, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Home Remedies:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  ...response.remedies.map((remedy) => Padding(
                    padding: EdgeInsets.only(left: 32, top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: TextStyle(fontSize: 16)),
                        Expanded(
                          child: Text(remedy, style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
          
          if (response.remedies.isNotEmpty)
            SizedBox(height: 16),
          
          // Disclaimer
          Text(
            response.disclaimer,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
  
  // MODERATE UI: Orange theme, doctor recommendation
  Widget _buildModerateUI(SymptomResponse response) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Severity badge (orange)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Severity: MODERATE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          
          // Doctor recommendation box
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.medical_services, color: Colors.orange[800], size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'RECOMMENDED ACTION',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  'Schedule a doctor consultation within 24-48 hours',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.orange[900],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          
          // Analysis
          Text(
            'Analysis:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(response.answer, style: TextStyle(fontSize: 16)),
          SizedBox(height: 16),
          
          // Disclaimer
          Text(
            response.disclaimer,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
  
  // SEVERE UI: Red theme, urgent messaging
  Widget _buildSevereUI(SymptomResponse response) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Severity badge (red)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Severity: SEVERE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          
          // URGENT warning box
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red, width: 3),
            ),
            child: Column(
              children: [
                Icon(Icons.local_hospital, color: Colors.red[700], size: 48),
                SizedBox(height: 12),
                Text(
                  '⚠️ URGENT MEDICAL ATTENTION NEEDED',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[900],
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Seek immediate medical care. Consider visiting emergency room if symptoms are acute.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red[900],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          
          // Analysis
          Text(
            'Analysis:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(response.answer, style: TextStyle(fontSize: 16)),
          SizedBox(height: 16),
          
          // Disclaimer
          Text(
            response.disclaimer,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
  
  // Default UI: Fallback for unknown severity
  Widget _buildDefaultUI(SymptomResponse response) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Severity: ${response.severity}',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 16),
          Text('Analysis:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(response.answer, style: TextStyle(fontSize: 16)),
          SizedBox(height: 16),
          Text(
            response.disclaimer,
            style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
  
  // OLD METHOD: Keep for color reference (not used in new UI)
  Color _getSeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'MILD':
        return Colors.green;
      case 'MODERATE':
        return Colors.orange;
      case 'SEVERE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}