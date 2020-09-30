import 'package:acs_upb_mobile/authentication/model/user.dart';
import 'package:acs_upb_mobile/authentication/service/auth_provider.dart';
import 'package:acs_upb_mobile/generated/l10n.dart';
import 'package:acs_upb_mobile/pages/settings/model/request.dart';
import 'package:acs_upb_mobile/pages/settings/service/request_provider.dart';
import 'package:acs_upb_mobile/widgets/scaffold.dart';
import 'package:acs_upb_mobile/widgets/button.dart';
import 'package:acs_upb_mobile/widgets/dialog.dart';
import 'package:acs_upb_mobile/widgets/toast.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AskPermissions extends StatefulWidget {
  static const String routeName = '/requestPermissions';

  @override
  State<StatefulWidget> createState() => _AskPermissionsState();
}

class _AskPermissionsState extends State<AskPermissions> {
  User user;
  String requestBody = '';
  bool agreedToResponsibilities = false;
  RequestProvider requestProvider;

  Future<void> _fetchUser() async {
    final AuthProvider authProvider = Provider.of(context, listen: false);
    user = await authProvider.currentUser;
    if (mounted) {
      setState(() {});
    }
  }

  AppDialog _informExistingRequest(BuildContext context) {
    return AppDialog(
      title: S.of(context).warning,
      content: [
        Text(S.of(context).messageRequestAlreadyExists),
      ],
      actions: [
        AppButton(
            key: const ValueKey('agree_overwrite_request'),
            text: S.of(context).buttonSend,
            color: Theme.of(context).accentColor,
            width: 130,
            onTap: () async {
              await sendRequest(context);
              Navigator.of(context).pop();
            }),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> sendRequest(BuildContext context) async {
    final queryResult = await requestProvider
        .makeRequest(Request(user.uid, requestBody), context: context);
    if (queryResult) {
      AppToast.show(S.of(context).messageRequestHasBeenSent);
      Navigator.of(context).pop();
    } else {
      AppToast.show(S.of(context).errorSomethingWentWrong);
    }
  }

  @override
  Widget build(BuildContext context) {
    requestProvider = Provider.of<RequestProvider>(context, listen: false);

    return AppScaffold(
        title: S.of(context).navigationAskPermissions,
        actions: [
          AppScaffoldAction(
              text: S.of(context).buttonSave,
              onPressed: () async {
                if (!agreedToResponsibilities) {
                  AppToast.show(
                      '${S.of(context).warningAgreeTo}${S.of(context).labelPermissionsConsent}.');
                  return;
                }

                if (requestBody == '') {
                  AppToast.show(S.of(context).warningRequestEmpty);
                  return;
                }

                /*
                 * Check if there is already a request registered for the current
                 * user.
                 */
                final queryResult = await requestProvider
                    .userAlreadyRequested(user.uid, context: context);

                if (queryResult) {
                  await showDialog(
                      context: context, child: _informExistingRequest(context));
                  return;
                }

                await sendRequest(context);
              })
        ],
        body: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                  height: MediaQuery.of(context).size.height / 4,
                  child: Image.asset('assets/illustrations/undraw_hiring.png')),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                S.of(context).messageAskPermissionToEdit,
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: TextFormField(
                keyboardType: TextInputType.multiline,
                minLines: 1,
                maxLines: 10,
                onChanged: (newRequestBody) =>
                    setState(() => requestBody = newRequestBody),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(children: [
                Checkbox(
                  value: agreedToResponsibilities,
                  visualDensity: VisualDensity.compact,
                  onChanged: (value) =>
                      setState(() => agreedToResponsibilities = value),
                ),
                Expanded(
                    child: Text(
                  S.of(context).messageAgreePermissions,
                  style: Theme.of(context).textTheme.subtitle1,
                )),
              ]),
            ),
          ],
        ));
  }
}
