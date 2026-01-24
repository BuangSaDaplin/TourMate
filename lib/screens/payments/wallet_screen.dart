import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Login Required")));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('My Wallet'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. Balance Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              boxShadow: [
                BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
              ],
            ),
            child: Column(
              children: [
                const Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2));
                    
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    final balance = (data?['walletBalance'] ?? 0.0) as num;

                    return Text(
                      '₱${NumberFormat('#,##0.00').format(balance)}',
                      style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                    );
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _showWithdrawDialog(context, user.uid),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text("Withdraw Funds"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          ),

          // 2. Transaction List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('wallet_transactions')
                  .where('userId', isEqualTo: user.uid)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('No transactions yet', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    final amount = (data['amount'] ?? 0.0) as num;
                    final type = data['type'] ?? 'unknown';
                    final isCredit = amount > 0;
                    final date = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

                    // Icon Logic
                    IconData icon;
                    Color color;
                    if (type == 'withdrawal') {
                      icon = Icons.arrow_upward;
                      color = Colors.red;
                    } else if (type == 'refund') {
                      icon = Icons.replay;
                      color = Colors.orange;
                    } else { // earning
                      icon = Icons.arrow_downward;
                      color = Colors.green;
                    }

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.1),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        title: Text(data['description'] ?? 'Transaction', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(DateFormat('MMM dd • h:mm a').format(date)),
                        trailing: Text(
                          '${isCredit ? '+' : ''}₱${NumberFormat('#,##0.00').format(amount)}',
                          style: TextStyle(
                            color: isCredit ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, String userId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Withdraw"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Amount",
            prefixText: "₱ ",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount > 0) {
                // Simulate Withdrawal
                await FirebaseFirestore.instance.collection('users').doc(userId).update({
                  'walletBalance': FieldValue.increment(-amount),
                });
                await FirebaseFirestore.instance.collection('wallet_transactions').add({
                  'userId': userId,
                  'amount': -amount,
                  'type': 'withdrawal',
                  'description': 'Withdrawal to Bank',
                  'timestamp': FieldValue.serverTimestamp(),
                  'status': 'pending',
                });
                if(context.mounted) Navigator.pop(context);
              }
            },
            child: const Text("Confirm"),
          )
        ],
      ),
    );
  }
}