import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'full_screen_image.dart';
import 'dart:async';

class MarketItemPage extends StatelessWidget {
  final Map<String, dynamic> item;
  const MarketItemPage({required this.item, super.key});

  @override
  Widget build(BuildContext context) {
    return MyMarketItemPage(item: item);
  }
}

class MyMarketItemPage extends StatefulWidget {
  final Map<String, dynamic> item;
  const MyMarketItemPage({required this.item, super.key});

  @override
  State<MyMarketItemPage> createState() => _MyMarketItemPageState();
}

class _MyMarketItemPageState extends State<MyMarketItemPage> {
  late final List<String> images;
  String name = "";
  String dept = "";
  String ph = "";
  String email = "";
  late final TextEditingController otpcontroller;

  final PageController controller = PageController();
  bool isRequested = false;
  bool _reqaccept = false;
  bool _alrExist = false;
  bool _isVerified = false;
  bool _isLoadingUser = true;
  bool _isLoadingRequest = true;
  bool _isUpdating = false;
  String? _requestId;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _requestSubscription;

  CollectionReference<Map<String, dynamic>> get _requestsCollection =>
      FirebaseFirestore.instance.collection('requests');

  @override
  void initState() {
    super.initState();
    otpcontroller = TextEditingController();
    images = List<String>.from(widget.item['imageUrls']);

    _listenToRequestState();
    getOwner();
  }

  @override
  void dispose() {
    _requestSubscription?.cancel();
    otpcontroller.dispose();
    controller.dispose();
    super.dispose();
  }

  void _setRequestStateFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> querySnapshot,
  ) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    QueryDocumentSnapshot<Map<String, dynamic>>? myRequestDoc;
    bool otherActiveRequestExists = false;

    for (final doc in querySnapshot.docs) {
      final data = doc.data();
      final status = data['status'];
      final isActive = status == 'pending' || status == 'accepted';

      if (!isActive) continue;

      if (data['requesterId'] == uid) {
        myRequestDoc = doc;
      } else {
        otherActiveRequestExists = true;
      }
    }

    final request = myRequestDoc?.data();
    final status = request?['status'];

    setState(() {
      _requestId = myRequestDoc?.id;
      isRequested = status == 'pending';
      _reqaccept = status == 'accepted';
      _isVerified = request?['acceptedAt'] != null;
      _alrExist = myRequestDoc == null && otherActiveRequestExists;
      _isLoadingRequest = false;
    });
  }

  void _listenToRequestState() {
    _requestSubscription = _requestsCollection
        .where('itemId', isEqualTo: widget.item['itemId'])
        .snapshots()
        .listen(
          (querySnapshot) {
            if (!mounted) return;
            _setRequestStateFromSnapshot(querySnapshot);
          },
          onError: (_) {
            if (!mounted) return;
            setState(() => _isLoadingRequest = false);
            Fluttertoast.showToast(msg: "Could not load request");
          },
        );
  }

  Future<void> _loadRequestState() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('itemId', isEqualTo: widget.item['itemId'])
          .get();

      if (!mounted) return;
      _setRequestStateFromSnapshot(querySnapshot);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingRequest = false);
      Fluttertoast.showToast(msg: "Could not load request");
    }
  }

  Future<bool> sendRequest() async {
    final requesterId = FirebaseAuth.instance.currentUser!.uid;

    final ownerId = widget.item['userId'];
    final itemId = widget.item['itemId'];

    if (_requestId != null && isRequested) {
      await _requestsCollection.doc(_requestId).delete();
      return false;
    }

    final existing = await _requestsCollection
        .where('itemId', isEqualTo: itemId)
        .get();

    for (final doc in existing.docs) {
      final data = doc.data();
      final status = data['status'];
      final isActive = status == 'pending' || status == 'accepted';

      if (!isActive) continue;

      if (data['requesterId'] == requesterId && status == 'pending') {
        await doc.reference.delete();
        return false;
      }

      if (data['requesterId'] == requesterId && status == 'accepted') {
        _requestId = doc.id;
        _reqaccept = true;
        _isVerified = data['acceptedAt'] != null;
        return false;
      }

      if (data['requesterId'] != requesterId) {
        _alrExist = true;
        return false;
      }
    }

    final newRequest = await _requestsCollection.add({
      "itemId": itemId,
      "ownerId": ownerId,
      "requesterId": requesterId,
      "status": "pending",
      "name": widget.item['name'],
      "rent": widget.item['rent'],
      "desc": widget.item['desc'],
      "imageUrls": widget.item['imageUrls'] ?? [],
      "createdAt": FieldValue.serverTimestamp(),
    });

    _requestId = newRequest.id;
    return true;
  }

  Future<void> endRequest(String requestId) async {
    await FirebaseFirestore.instance
        .collection('requests')
        .doc(requestId)
        .delete();
  }

  Future<void> getOwner() async {
    try {
      final map = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.item['userId'])
          .get();
      final user = map.data();
      if (!mounted) return;

      setState(() {
        name = user?['name']?.toString() ?? "Unknown";
        dept = user?['department']?.toString() ?? "Unknown";
        ph = user?['phone']?.toString() ?? "Unknown";
        email = user?['email']?.toString() ?? "Unknown";
        _isLoadingUser = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingUser = false);
      Fluttertoast.showToast(msg: "Could not load owner details");
    }
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingUser = true;
      _isLoadingRequest = true;
    });

    await Future.wait([_loadRequestState(), getOwner()]);
  }

  Future<bool> _verifyOtp() async {
    final requestId = _requestId;

    if (requestId == null) {
      Fluttertoast.showToast(msg: "Request not found");
      return false;
    }

    final doc = await _requestsCollection.doc(requestId).get();
    final data = doc.data();

    if (!doc.exists || data == null || data['status'] != 'accepted') {
      Fluttertoast.showToast(msg: "Request is not accepted yet");
      return false;
    }

    if (otpcontroller.text.trim() != data['otp']?.toString()) {
      Fluttertoast.showToast(msg: "Invalid verification code");
      return false;
    }

    await _requestsCollection.doc(requestId).update({
      "acceptedAt": FieldValue.serverTimestamp(),
    });

    return true;
  }

  Future<double?> _completeRent() async {
    final requestId = _requestId;

    if (requestId == null) {
      Fluttertoast.showToast(msg: "Request not found");
      return null;
    }

    final doc = await _requestsCollection.doc(requestId).get();
    final data = doc.data();

    if (!doc.exists || data == null) {
      Fluttertoast.showToast(msg: "Request no longer exists");
      return null;
    }

    final acceptedAt = data['acceptedAt'];
    if (acceptedAt is! Timestamp) {
      Fluttertoast.showToast(msg: "Rent has not started yet");
      return null;
    }

    final startTime = acceptedAt.toDate();
    final duration = DateTime.now().difference(startTime);
    final hours = duration.inMinutes <= 60 ? 1.0 : duration.inMinutes / 60.0;
    final rate = double.tryParse(widget.item['rent'].toString());

    if (rate == null) {
      Fluttertoast.showToast(msg: "Invalid rent amount");
      return null;
    }

    final finalAmount = double.parse((hours * rate).toStringAsFixed(2));
    await endRequest(requestId);
    return finalAmount;
  }

  ButtonStyle _actionButtonStyle(Color color, {Color? pressedColor}) {
    return ButtonStyle(
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
      minimumSize: WidgetStatePropertyAll(Size(double.infinity, 40)),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (pressedColor != null && states.contains(WidgetState.pressed)) {
          return pressedColor;
        }
        return color;
      }),
      foregroundColor: WidgetStatePropertyAll(Colors.white),
    );
  }

  Future<void> _handleRequestButton() async {
    setState(() => _isUpdating = true);

    try {
      final newState = await sendRequest();

      if (!mounted) return;
      setState(() {
        isRequested = newState;
        if (newState) {
          _alrExist = false;
        } else if (!_alrExist && !_reqaccept) {
          _requestId = null;
        }
      });

      Fluttertoast.showToast(
        msg: _reqaccept
            ? "Request already accepted"
            : (_alrExist
                  ? "Item already requested"
                  : (newState ? "Request sent" : "Request cancelled")),
      );
    } catch (_) {
      Fluttertoast.showToast(msg: "Could not update request");
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _handleVerifyOtp() async {
    setState(() => _isUpdating = true);

    try {
      final verified = await _verifyOtp();

      if (!mounted) return;
      setState(() {
        _isVerified = verified;
      });

      if (verified) {
        Fluttertoast.showToast(msg: "Rent started");
      }
    } catch (_) {
      Fluttertoast.showToast(msg: "Could not verify code");
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  void _showCompleteRentDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text("Confirm Complete Rent?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              setState(() => _isUpdating = true);

              double? finalAmount;
              try {
                finalAmount = await _completeRent();
              } catch (_) {
                Fluttertoast.showToast(msg: "Could not complete rent");
              }

              if (!mounted) return;
              setState(() {
                _isUpdating = false;
                if (finalAmount != null) {
                  _requestId = null;
                  isRequested = false;
                  _reqaccept = false;
                  _isVerified = false;
                }
              });

              if (finalAmount == null) return;

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (resultDialogContext) => AlertDialog(
                  title: Text("Total Rent: $finalAmount"),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(resultDialogContext).pop();
                        Navigator.of(context).maybePop();
                      },
                      child: Text("Done"),
                    ),
                  ],
                ),
              );
            },
            child: Text("Confirm"),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestActions() {
    if (_isLoadingRequest) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isUpdating) {
      return ElevatedButton.icon(
        onPressed: null,
        style: _actionButtonStyle(Colors.deepPurple),
        icon: Icon(Icons.hourglass_empty),
        label: Text("Please wait...", style: TextStyle(fontSize: 16)),
      );
    }

    if (_reqaccept) {
      if (_isVerified) {
        return ElevatedButton.icon(
          onPressed: _showCompleteRentDialog,
          style: _actionButtonStyle(
            Colors.deepPurple,
            pressedColor: const Color.fromARGB(255, 68, 38, 121),
          ),
          icon: Icon(Icons.check_circle_outline),
          label: Text("Complete Rent", style: TextStyle(fontSize: 16)),
        );
      }

      return Column(
        children: [
          TextField(
            controller: otpcontroller,
            keyboardType: TextInputType.numberWithOptions(),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.verified_user_outlined),
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.deepPurple, width: 2.0),
              ),
              label: Text("Verification Code"),
              floatingLabelStyle: TextStyle(color: Colors.deepPurple),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
            ),
          ),
          ElevatedButton.icon(
            onPressed: _handleVerifyOtp,
            style: _actionButtonStyle(
              Colors.deepPurple,
              pressedColor: const Color.fromARGB(255, 68, 38, 121),
            ),
            icon: Icon(Icons.verified_outlined),
            label: Text("Verify", style: TextStyle(fontSize: 16)),
          ),
        ],
      );
    }

    return ElevatedButton.icon(
      onPressed: _alrExist ? null : _handleRequestButton,
      style: _actionButtonStyle(
        Colors.deepPurple,
        pressedColor: const Color.fromARGB(255, 68, 38, 121),
      ),
      icon: Icon(
        _alrExist
            ? Icons.lock_outline
            : (isRequested ? Icons.cancel_outlined : Icons.send_outlined),
      ),
      label: Text(
        _alrExist
            ? "Item already requested"
            : (isRequested ? "Cancel Request" : "Request Item"),
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Item Details"), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  SizedBox(
                    height: 250,
                    child: PageView.builder(
                      controller: controller,
                      itemCount: images.length,
                      itemBuilder: (context, idx) {
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) {
                                  return FullScreenImageViewer(
                                    images: images,
                                    initialIndex: idx,
                                  );
                                },
                              ),
                            );
                          },
                          child: Image.network(images[idx], fit: BoxFit.cover),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 5),
                  SmoothPageIndicator(
                    controller: controller,
                    count: images.length,
                    effect: WormEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      paintStyle: PaintingStyle.stroke,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: Colors.deepPurple,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${widget.item['name']}",
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.currency_rupee, size: 20),
                                  Text(
                                    "${widget.item['rent']} /hr",
                                    style: TextStyle(fontSize: 20),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: Colors.deepPurple,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.notes_outlined, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    "Description:",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Text("${widget.item['desc']}"),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: Colors.deepPurple,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.person_outline),
                                  SizedBox(width: 8),
                                  Text(
                                    "Owner Details:",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              _isLoadingUser
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : Text(
                                      "Name: $name\nDepartment: $dept\nPh no: $ph\nEmail: $email",
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [_buildRequestActions()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

