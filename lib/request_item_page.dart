import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'full_screen_image.dart';
import 'dart:async';
import 'dart:math';

String generateOtp() {
  final random = Random();
  return (1000 + random.nextInt(9000)).toString();
}

class RequestItemPage extends StatelessWidget {
  final Map<String, dynamic> item;
  const RequestItemPage({required this.item, super.key});

  @override
  Widget build(BuildContext context) {
    return MyRequestItemPage(item: item);
  }
}

class MyRequestItemPage extends StatefulWidget {
  final Map<String, dynamic> item;
  const MyRequestItemPage({required this.item, super.key});

  @override
  State<MyRequestItemPage> createState() => _MyRequestItemPageState();
}

class _MyRequestItemPageState extends State<MyRequestItemPage> {
  late final List<String> images;
  String name = "";
  String dept = "";
  String ph = "";
  String email = "";

  final PageController controller = PageController();

  String msg = "";
  bool _isRented = false;
  bool _requestExists = true;
  bool _isLoadingUser = true;
  bool _isLoadingRequest = true;
  bool _isUpdating = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _requestSubscription;

  String get _requestId => widget.item['requestId'].toString();

  DocumentReference<Map<String, dynamic>> get _requestRef =>
      FirebaseFirestore.instance.collection('requests').doc(_requestId);

  void _setRequestStateFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> requestDoc,
  ) {
    final request = requestDoc.data();

    if (!requestDoc.exists || request == null) {
      setState(() {
        msg = "";
        _isRented = false;
        _requestExists = false;
        _isLoadingRequest = false;
      });
      return;
    }

    final otp = request['otp']?.toString();
    final isAccepted = request['status'] == 'accepted';
    final hasStartedRent = request['acceptedAt'] != null;

    setState(() {
      msg = isAccepted
          ? (otp == null || otp.isEmpty
                ? "Request accepted"
                : "Verification Code: $otp")
          : "";
      _isRented = hasStartedRent;
      _requestExists = true;
      _isLoadingRequest = false;
    });
  }

  void _listenToRequestState() {
    _requestSubscription = _requestRef.snapshots().listen(
      (requestDoc) {
        if (!mounted) return;
        _setRequestStateFromSnapshot(requestDoc);
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
      final requestDoc = await _requestRef.get();
      if (!mounted) return;

      _setRequestStateFromSnapshot(requestDoc);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingRequest = false);
      Fluttertoast.showToast(msg: "Could not load request");
    }
  }

  Future<void> acceptRequest(String requestId) async {
    final otp = generateOtp();

    await FirebaseFirestore.instance
        .collection('requests')
        .doc(requestId)
        .update({"status": "accepted", "otp": otp});

    if (mounted) {
      setState(() {
        msg = "Verification Code: $otp";
        _isRented = false;
      });
    }
  }

  Future<void> rejectRequest(String requestId) async {
    await FirebaseFirestore.instance
        .collection('requests')
        .doc(requestId)
        .delete();
  }

  @override
  void initState() {
    super.initState();
    images = List<String>.from(widget.item['imageUrls'] ?? []);
    _listenToRequestState();
    getOwner();
  }

  @override
  void dispose() {
    _requestSubscription?.cancel();
    controller.dispose();
    super.dispose();
  }

  Future<void> getOwner() async {
    try {
      final map = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.item['requesterId'])
          .get();
      final user = map.data();
      if (!mounted) return;

      setState(() {
        name = user?['name']?.toString() ?? "";
        dept = user?['department']?.toString() ?? "";
        ph = user?['phone']?.toString() ?? "";
        email = user?['email']?.toString() ?? "";
        _isLoadingUser = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingUser = false);
      Fluttertoast.showToast(msg: "Could not load requester details");
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

  Future<double?> _completeRent() async {
    final requestDoc = await _requestRef.get();
    final request = requestDoc.data();

    if (!requestDoc.exists || request == null) {
      Fluttertoast.showToast(msg: "Request no longer exists");
      return null;
    }

    final acceptedAt = request['acceptedAt'];
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
    await rejectRequest(_requestId);
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

  Future<void> _acceptCurrentRequest() async {
    setState(() => _isUpdating = true);

    try {
      await acceptRequest(_requestId);
      Fluttertoast.showToast(msg: "Request accepted");
    } catch (_) {
      Fluttertoast.showToast(msg: "Could not accept request");
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  void _showRejectDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text("Confirm Reject?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              setState(() => _isUpdating = true);

              try {
                await rejectRequest(_requestId);
                Fluttertoast.showToast(msg: "Request rejected");

                if (!mounted) return;
                Navigator.of(context).pop();
              } catch (_) {
                Fluttertoast.showToast(msg: "Could not reject request");
                if (mounted) {
                  setState(() => _isUpdating = false);
                }
              }
            },
            child: Text("Confirm"),
          ),
        ],
      ),
    );
  }

  void _showCompleteRentDialog(BuildContext context) {
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
                  _isRented = false;
                  msg = "";
                }
              });

              if (finalAmount == null) return;

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (resultDialogContext) => AlertDialog(
                  title: Text("Total Rent: ₹ $finalAmount"),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(resultDialogContext).pop();
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
        style: _actionButtonStyle(const Color.fromARGB(255, 149, 113, 248)),
        icon: Icon(Icons.hourglass_empty),
        label: Text("Please wait...", style: TextStyle(fontSize: 16)),
      );
    }

    if (!_requestExists) {
      return ElevatedButton.icon(
        onPressed: null,
        style: _actionButtonStyle(const Color.fromARGB(255, 149, 113, 248)),
        icon: Icon(Icons.info_outline),
        label: Text(
          "Request no longer available",
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    if (_isRented) {
      return ElevatedButton.icon(
        onPressed: () {
          _showCompleteRentDialog(context);
        },
        style: _actionButtonStyle(Colors.deepPurple),
        icon: Icon(Icons.check_circle_outline),
        label: Text("Complete rent", style: TextStyle(fontSize: 16)),
      );
    }

    if (msg.isNotEmpty) {
      return ElevatedButton.icon(
        onPressed: null,
        style: _actionButtonStyle(const Color.fromARGB(255, 149, 113, 248)),
        icon: Icon(Icons.pin_outlined),
        label: Text(msg, style: TextStyle(fontSize: 16)),
      );
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _showRejectDialog,
            style: _actionButtonStyle(
              Colors.red,
              pressedColor: const Color.fromARGB(255, 155, 48, 41),
            ),
            icon: Icon(Icons.close),
            label: Text("Reject", style: TextStyle(fontSize: 16)),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _acceptCurrentRequest,
            style: _actionButtonStyle(
              Colors.green,
              pressedColor: const Color.fromARGB(255, 43, 95, 45),
            ),
            icon: Icon(Icons.check),
            label: Text("Accept", style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
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
                    child: images.isEmpty
                        ? Container(
                            width: double.infinity,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 60),
                          )
                        : PageView.builder(
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
                                child: Image.network(
                                  images[idx],
                                  fit: BoxFit.cover,
                                ),
                              );
                            },
                          ),
                  ),
                  if (images.isNotEmpty) ...[
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
                                    "Requester Details:",
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
